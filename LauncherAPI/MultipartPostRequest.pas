unit MultipartPostRequest;

interface

uses
  Classes, CodepageAPI;

type
  TMultipartPostRequest = class(TMemoryStream)
    private const
      CRLF = #13#10;
      DefaultBoundary : string = 'DisIsUniqueBoundary4POSTRequestYouShouldUseInYourFuckingApps';
      DefaultHeader   : string = 'multipart/form-data; boundary=';
    private
      FBoundary: string;
    public
      property Boundary: string read FBoundary write FBoundary;

      constructor Create;
      destructor Destroy; override;
      procedure AddTextField(const Parameter, Value: string);
      procedure AddFileField(const FileStream: TMemoryStream; const Parameter, Value, ContentType: string);
      procedure FinalizeRequest;
      function GetHeader: string;
  end;

implementation

{ TMultipartPostRequest }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TMultipartPostRequest.Create;
begin
  inherited;
  FBoundary := DefaultBoundary;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

destructor TMultipartPostRequest.Destroy;
begin
  inherited;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMultipartPostRequest.AddTextField(const Parameter, Value: string);
var
  Field: AnsiString;
begin
  if Self.Size <> 0 then
    Self.Write(PAnsiChar(CRLF)^, Length(CRLF));

  Field := WideToAnsi('--' + FBoundary + CRLF +
           'Content-Disposition: form-data; name="' + Parameter + '"' + CRLF +
           CRLF +
           Value);

  Self.Write(PAnsiChar(Field)^, Length(Field));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMultipartPostRequest.AddFileField(const FileStream: TMemoryStream;
  const Parameter, Value, ContentType: string);
var
  Field: AnsiString;
begin
  if Self.Size <> 0 then
    Self.Write(PAnsiChar(CRLF)^, Length(CRLF));

  Field := WideToAnsi('--' + FBoundary + CRLF +
           'Content-Disposition: form-data; name="' + Parameter + '"; filename="' + Value + '"' + CRLF +
           'Content-Type: ' + ContentType + CRLF +
           CRLF);

  Self.Write(PAnsiChar(Field)^, Length(Field));
  Self.Write(FileStream.Memory^, FileStream.Size);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMultipartPostRequest.FinalizeRequest;
var
  FinalBoundary: AnsiString;
begin
  if Self.Size = 0 then Self.Write(PAnsiChar(CRLF)^, Length(CRLF));
  FinalBoundary := WideToAnsi(CRLF + '--' + FBoundary + '--' + CRLF);
  Self.Write(PAnsiChar(FinalBoundary)^, Length(FinalBoundary));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function TMultipartPostRequest.GetHeader: string;
begin
  Result := DefaultHeader + FBoundary;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end.
