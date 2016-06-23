unit HTTPUtils;

interface

uses
  Windows, SysUtils, Classes, ZLib,
  HTTPSend, synautil, blcksock, ssl_openssl,
  FileAPI, StringsAPI, CodepageAPI;

type
  TDownloadInfo = record
    IsDownloaded    : Boolean;
    FileSize        : Integer;
    BytesDownloaded : Integer;
    TickDownloaded  : Integer; // Скачано за одно событие
    Link            : string;
    Destination     : string;
  end;

  TOnDownload = reference to procedure(const DownloadInfo: TDownloadInfo);
  THTTPSender = class
    private
      FHTTPSend: THTTPSend;

      // Настройки соединения:
      FTimeout    : Integer;
      FUseGZip    : Boolean;
      FMimeType   : string;

      // Статус выполнения запроса:
      FStatus       : Boolean;
      FStatusCode   : Integer;
      FStatusString : string;

      // Событие загрузки:
      FDownloadInfo  : TDownloadInfo;
      FOnDownload    : TOnDownload;
      FPartialSaving : Boolean;
      FileHandle     : THandle;

      function FixHost(const Host: string): string;
      procedure SetupHTTPSend;
      procedure LoadRequestByString(const Request: string);
      procedure OnSockStatus(Sender: TObject; Reason: THookSocketReason; const Value: string);
      procedure GZipDecode;
      procedure GZipDecompress(const CompressedStream, DecompressedStream: TMemoryStream);
      procedure FillStatus;
    public
      property HTTPSend: THTTPSend read FHTTPSend;

      property Timeout  : Integer read FTimeout  write FTimeout;
      property UseGZip  : Boolean read FUseGZip  write FUseGZip;
      property MimeType : string  read FMimeType write FMimeType;

      property Status       : Boolean read FStatus;
      property StatusCode   : Integer read FStatusCode;
      property StatusString : string  read FStatusString;

      constructor Create;
      destructor Destroy; override;

      function POST(const Host, Request: string; const Response: TStringStream = nil): Boolean; overload;
      function POST(const Host: string; const Request: TStream; const Response: TStringStream = nil): Boolean; overload;
      function GET(const Host: string; const Response: TStringStream = nil): Boolean;
      function DownloadFile(const Host, Destination: string; OnDownload: TOnDownload = nil; PartialSaving: Boolean = False): Boolean; overload;
      function DownloadFile(const Host: string; OnDownload: TOnDownload = nil): Boolean; overload;

      function IsSuccessfulStatus: Boolean;
      procedure FillResponse(const Response: TStringStream);

      procedure Clear;
  end;

implementation

{ HTTPSender }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.GZipDecode;
begin
  // Если приняли GZip - распаковываем:
  HeadersToList(FHTTPSend.Headers);
  if Trim(FHTTPSend.Headers.Values['Content-Encoding']) = 'gzip' then
    GZipDecompress(FHTTPSend.Document, FHTTPSend.Document);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.GZipDecompress(const CompressedStream, DecompressedStream: TMemoryStream);
var
  DecompressionStream: TZDecompressionStream;
  IntermediateBuffer: TMemoryStream;
begin
  DecompressionStream := TZDecompressionStream.Create(CompressedStream, 15 + 32);
  IntermediateBuffer := TMemoryStream.Create;
  IntermediateBuffer.LoadFromStream(DecompressionStream);
  DecompressedStream.LoadFromStream(IntermediateBuffer);
  IntermediateBuffer.Free;
  DecompressionStream.Free;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function THTTPSender.IsSuccessfulStatus: Boolean;
begin
  Result := FStatus and (FStatusCode >= 200) and (FStatusCode < 300);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.LoadRequestByString(const Request: string);
var
  RequestStream: TStringStream;
begin
  RequestStream := TStringStream.Create;
  RequestStream.Clear;
  RequestStream.WriteString(Request);
  FHTTPSend.Document.LoadFromStream(RequestStream);
  FreeAndNil(RequestStream);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.Clear;
begin
  FHTTPSend.Clear;
  FHTTPSend.Cookies.Clear;
  FHTTPSend.Sock.OnStatus := nil;
  FOnDownload := nil;

  with FDownloadInfo do
  begin
    IsDownloaded    := False;
    FileSize        := 0;
    BytesDownloaded := 0;
    TickDownloaded  := 0;
    Link            := '';
    Destination     := '';
  end;

  FStatus       := False;
  FStatusCode   := 0;
  FStatusString := '';

  FPartialSaving := False;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor THTTPSender.Create;
begin
  FHTTPSend := THTTPSend.Create;
  FHTTPSend.Protocol := '1.1';

  FMimeType := 'application/x-www-form-urlencoded';
  FUseGZip  := False;
  FTimeout  := 10000;

  Clear;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

destructor THTTPSender.Destroy;
begin
  Clear;
  FreeAndNil(FHTTPSend);
  inherited;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.OnSockStatus(Sender: TObject; Reason: THookSocketReason;
  const Value: string);
begin
  if Reason = HR_READCOUNT then
  begin
    with FDownloadInfo do
    begin
      FileSize       := FHTTPSend.DownloadSize;
      TickDownloaded := StrToInt(Value);
      Inc(BytesDownloaded, TickDownloaded);
    end;

    if FPartialSaving then
    begin
      WriteToFile(FileHandle, FHTTPSend.Document.Memory, FHTTPSend.Document.Size);
      FHTTPSend.Document.Clear;
    end;

    if Assigned(FOnDownload) then FOnDownload(FDownloadInfo);

    FDownloadInfo.TickDownloaded := 0;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.FillResponse(const Response: TStringStream);
begin
  if Assigned(Response) then
  begin
    if FStatus then
      Response.LoadFromStream(FHTTPSend.Document)
    else
      Response.Clear;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.FillStatus;
begin
  FStatusCode   := FHTTPSend.ResultCode;
  FStatusString := FHTTPSend.ResultString;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function THTTPSender.FixHost(const Host: string): string;
var
  C: AnsiString;
  ReplacingSymbol: string;
const
  Chars = [' '..'$', ''''..',', ';'..'<', '>', '@', '['..'^', '`', '{'..'~'];
begin
  Result := FixSlashes(Host, True);
  for C in Chars do
  begin
    ReplacingSymbol := AnsiToWide(C);
    Result := ReplaceParam(Result, ReplacingSymbol, '%' + IntToHex(Byte(PChar(ReplacingSymbol)^), 2));
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THTTPSender.SetupHTTPSend;
begin
  FHTTPSend.MimeType := FMimeType;

  if FUseGZip then FHTTPSend.Headers.Add('Accept-Encoding: gzip');

  if FTimeout > 0 then
  begin
    FHTTPSend.Timeout := FTimeout;
    FHTTPSend.Sock.SetTimeout(FTimeout);
  end;
  
  if Assigned(FOnDownload) or FPartialSaving then
  begin
    FHTTPSend.Sock.OnStatus := OnSockStatus;
  end;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

function THTTPSender.POST(const Host, Request: string;
  const Response: TStringStream): Boolean;
begin
  Clear;
  SetupHTTPSend;

  LoadRequestByString(Request);
  FStatus := FHTTPSend.HTTPMethod('POST', FixHost(Host));
  GZipDecode;

  FillStatus;
  FillResponse(Response);
  Result := FStatus;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function THTTPSender.POST(const Host: string; const Request: TStream;
  const Response: TStringStream): Boolean;
begin
  Clear;
  SetupHTTPSend;

  FHTTPSend.Document.LoadFromStream(Request);
  FStatus := FHTTPSend.HTTPMethod('POST', FixHost(Host));
  GZipDecode;

  FillStatus;
  FillResponse(Response);
  Result := FStatus;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function THTTPSender.GET(const Host: string; const Response: TStringStream): Boolean;
begin
  Clear;
  SetupHTTPSend;

  FStatus := FHTTPSend.HTTPMethod('GET', FixHost(Host));
  GZipDecode;

  FillStatus;
  FillResponse(Response);
  Result := FStatus;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function THTTPSender.DownloadFile(const Host, Destination: string;
  OnDownload: TOnDownload; PartialSaving: Boolean): Boolean;
begin
  // Настраиваем HTTPSend:
  Clear;
  FOnDownload := OnDownload;
  FPartialSaving := PartialSaving;
  SetupHTTPSend;

  FDownloadInfo.Destination := Destination;
  FDownloadInfo.Link := Host;

  // Скачиваем файл:
  FileHandle := CreateFile(FDownloadInfo.Destination, CREATE_ALWAYS);

  FStatus := FHTTPSend.HTTPMethod('GET', FixHost(Host));
  Result := IsSuccessfulStatus;
  FillStatus;

  if not FPartialSaving then
    WriteToFile(FileHandle, FHTTPSend.Document.Memory, FHTTPSend.Document.Size);
  CloseHandle(FileHandle);

  // Выполняем финальное событие:
  if Assigned(FOnDownload) then
  begin
    FDownloadInfo.IsDownloaded := True;
    FOnDownload(FDownloadInfo);
  end;

  // Чистим память; если загрузка не удалась - стираем файл:
  FHTTPSend.Document.Clear;
  if not (FStatus and (FStatusCode < 300)) then DeleteFile(FDownloadInfo.Destination);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function THTTPSender.DownloadFile(const Host: string;
  OnDownload: TOnDownload): Boolean;
begin
  // Настраиваем HTTPSend:
  Clear;
  FOnDownload := OnDownload;
  SetupHTTPSend;

  FDownloadInfo.Link := Host;

  FStatus := FHTTPSend.HTTPMethod('GET', FixHost(Host));
  FillStatus;
  Result := IsSuccessfulStatus;

  // Выполняем финальное событие:
  if Assigned(FOnDownload) then
  begin
    FDownloadInfo.IsDownloaded := True;
    FOnDownload(FDownloadInfo);
  end;
end;

end.
