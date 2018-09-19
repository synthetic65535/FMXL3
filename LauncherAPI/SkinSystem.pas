unit SkinSystem;

interface

uses
  SysUtils, UserInformation, HTTPUtils, System.JSON, CodepageAPI,
  JSONUtils, MultipartPostRequest, Classes, System.NetEncoding, Encryption,
  LauncherSettings;

type
  IMAGE_TYPE = (
    IMAGE_SKIN,
    IMAGE_CLOAK
  );

  ACTION_TYPE = (
    ACTION_SETUP,
    ACTION_DELETE,
    ACTION_DOWNLOAD
  );

  SKIN_SYSTEM_STATUS = (
    SKIN_SYSTEM_SUCCESS,
    SKIN_SYSTEM_FILE_NOT_EXISTS,
    SKIN_SYSTEM_NOT_PNG,
    SKIN_SYSTEM_CONNECTION_ERROR,
    SKIN_SYSTEM_UNKNOWN_ERROR,
    SKIN_SYSTEM_UNKNOWN_RESPONSE_FORMAT
  );

  TSkinSystemWrapper = class
    private const
      PNGSignature: Cardinal = $474E5089;
    private
      FErrorReason: string;
      function ParseResponse(Response: TStringStream; const ImageStream: TMemoryStream = nil): SKIN_SYSTEM_STATUS;
    public
      property ErrorReason: string read FErrorReason;

      constructor Create;
      destructor Destroy; override;

      function SetupImage   (const SkinSystemScriptAddress, Login, Password: string; const FileName: string; ImageType: IMAGE_TYPE; const UserInfo: TUserInfo): SKIN_SYSTEM_STATUS;
      function DeleteImage  (const SkinSystemScriptAddress, Login, Password: string; ImageType: IMAGE_TYPE; const UserInfo: TUserInfo): SKIN_SYSTEM_STATUS;
      function DownloadImage(const SkinSystemScriptAddress, Destination, Login, Password: string; ImageType: IMAGE_TYPE): SKIN_SYSTEM_STATUS;
  end;

implementation

const
  ImageTypes: array [0..1] of string = ('skin', 'cloak');

{ TSkinSystemWrapper }

constructor TSkinSystemWrapper.Create;
begin
  FErrorReason := '';
end;

destructor TSkinSystemWrapper.Destroy;
begin
  FErrorReason := '';
  inherited;
end;

function TSkinSystemWrapper.ParseResponse(Response: TStringStream; const ImageStream: TMemoryStream = nil): SKIN_SYSTEM_STATUS;
var
  ResponseJSON: TJSONObject;
  Status: string;
  ImageBase64: string;
  ImageBase64Stream: TStringStream;
  TempDataLength: Cardinal;
begin
  TempDataLength := Response.Size;
  DecryptRijndael(Response.Memory, TempDataLength, GetEncryptionKey());
  Response.Size := TempDataLength;
  UTF8Convert(Response);

  ResponseJSON := JSONStringToJSONObject(Response.DataString);
  if ResponseJSON = nil then
  begin
    FErrorReason := 'Неизвестный формат, полученный от скрипта системы скинов!';
    Exit(SKIN_SYSTEM_UNKNOWN_RESPONSE_FORMAT);
  end;

  Status := LowerCase(GetJSONStringValue(ResponseJSON, 'status'));
  if Status = 'success' then
  begin
    Result := SKIN_SYSTEM_SUCCESS;
    FErrorReason := 'Успешно!';
    if ImageStream = nil then Exit;

    ImageStream.Clear;
    if GetJSONStringValue(ResponseJSON, 'image', ImageBase64) then
    begin
      ImageBase64Stream := TStringStream.Create;
      ImageBase64Stream.Clear;
      ImageBase64Stream.WriteString(ImageBase64);
      ImageBase64Stream.Position := 0;
      TNetEncoding.Base64.Decode(ImageBase64Stream, ImageStream);
      FreeAndNil(ImageBase64Stream);
    end;
  end
  else
  begin
    Result := SKIN_SYSTEM_UNKNOWN_ERROR;
    if not GetJSONStringValue(ResponseJSON, 'reason', FErrorReason) then
      FErrorReason := 'Неизвестная ошибка!';
  end;

  FreeAndNil(ResponseJSON);
end;

function TSkinSystemWrapper.SetupImage(const SkinSystemScriptAddress, Login, Password: string;
  const FileName: string; ImageType: IMAGE_TYPE; const UserInfo: TUserInfo): SKIN_SYSTEM_STATUS;
var
  ImageStream: TMemoryStream;
  HTTPSender: THTTPSender;
  Request: TMultipartPostRequest;
  Response: TStringStream;
  EncryptedLogin, EncryptedPassword: AnsiString;
begin
  if not FileExists(FileName) then
  begin
    FErrorReason := 'Файл не найден!';
    Exit(SKIN_SYSTEM_FILE_NOT_EXISTS);
  end;

  ImageStream := TMemoryStream.Create;
  ImageStream.LoadFromFile(FileName);
  if LongWord(ImageStream.Memory^) <> PNGSignature then
  begin
    FreeAndNil(ImageStream);
    FErrorReason := 'Файл - не PNG!';
    Exit(SKIN_SYSTEM_NOT_PNG);
  end;

  EncryptedLogin := Login;
  EncryptedPassword := Password;
  EncryptRijndael(EncryptedLogin, GetEncryptionKey());
  EncryptRijndael(EncryptedPassword, GetEncryptionKey());

  Request := TMultipartPostRequest.Create;
  Request.AddTextField('login'     , HexEncode(EncryptedLogin));
  Request.AddTextField('password'  , HexEncode(EncryptedPassword));
  Request.AddTextField('action'    , 'setup');
  Request.AddTextField('image_type', ImageTypes[Integer(ImageType)]);
  Request.AddFileField(ImageStream , 'image', Login + '.png', 'image/png');
  Request.FinalizeRequest;

  Response := TStringStream.Create;
  Response.Clear;

  HTTPSender := THTTPSender.Create;
  HTTPSender.MimeType := Request.GetHeader;
  if not HTTPSender.POST(SkinSystemScriptAddress, Request, Response) then
  begin
    FreeAndNil(HTTPSender);
    FreeAndNil(ImageStream);
    FreeAndNil(Response);
    FErrorReason := 'Не удалось выполнить запрос! Проверьте доступность адреса!';
    Exit(SKIN_SYSTEM_CONNECTION_ERROR);
  end;

  FreeAndNil(HTTPSender);
  FreeAndNil(ImageStream);

  Result := ParseResponse(Response, nil);
  if Result = SKIN_SYSTEM_SUCCESS then
    case ImageType of
      IMAGE_SKIN  : UserInfo.SkinBitmap.LoadFromFile(FileName);
      IMAGE_CLOAK : UserInfo.CloakBitmap.LoadFromFile(FileName);
    end;
  FreeAndNil(Response);
end;

function TSkinSystemWrapper.DeleteImage(const SkinSystemScriptAddress, Login, Password: string;
  ImageType: IMAGE_TYPE; const UserInfo: TUserInfo): SKIN_SYSTEM_STATUS;
var
  HTTPSender: THTTPSender;
  Response: TStringStream;
  ImageStream: TMemoryStream;
  EncryptedLogin, EncryptedPassword: AnsiString;
begin
  Response := TStringStream.Create;
  Response.Clear;

  EncryptedLogin := Login;
  EncryptedPassword := Password;
  EncryptRijndael(EncryptedLogin, GetEncryptionKey());
  EncryptRijndael(EncryptedPassword, GetEncryptionKey());

  HTTPSender := THTTPSender.Create;
  if not HTTPSender.POST(
                          SkinSystemScriptAddress,
                          'login=' + HexEncode(EncryptedLogin) + '&password=' + HexEncode(EncryptedPassword) + '&action=delete&image_type=' + ImageTypes[Integer(ImageType)],
                          Response
                         ) then
  begin
    FreeAndNil(HTTPSender);
    FreeAndNil(Response);
    FErrorReason := 'Не удалось выполнить запрос! Проверьте доступность адреса!';
    Exit(SKIN_SYSTEM_CONNECTION_ERROR);
  end;

  FreeAndNil(HTTPSender);

  ImageStream := TMemoryStream.Create;
  ImageStream.Clear;
  Result := ParseResponse(Response, ImageStream);
  FreeAndNil(Response);

  if (Result = SKIN_SYSTEM_SUCCESS) and (ImageStream.Size > 0) then
  begin
    if LongWord(ImageStream.Memory^) <> PNGSignature then
    begin
      FreeAndNil(ImageStream);

      case ImageType of
        IMAGE_SKIN  : UserInfo.LoadInternalSkin;
        IMAGE_CLOAK : UserInfo.LoadInternalCloak;
      end;

      FErrorReason := 'Полученный файл - не PNG!';
      Exit(SKIN_SYSTEM_NOT_PNG);
    end;

    case ImageType of
      IMAGE_SKIN  : UserInfo.SkinBitmap.LoadFromStream(ImageStream);
      IMAGE_CLOAK : UserInfo.CloakBitmap.LoadFromStream(ImageStream);
    end;
  end
  else
  begin
    case ImageType of
      IMAGE_SKIN  : UserInfo.LoadInternalSkin;
      IMAGE_CLOAK : UserInfo.LoadInternalCloak;
    end;
  end;

end;

function TSkinSystemWrapper.DownloadImage(const SkinSystemScriptAddress, Destination, Login, Password: string;
  ImageType: IMAGE_TYPE): SKIN_SYSTEM_STATUS;
var
  HTTPSender: THTTPSender;
  Response: TStringStream;
  ImageStream: TMemoryStream;
  EncryptedLogin, EncryptedPassword: AnsiString;
begin
  Response := TStringStream.Create;
  Response.Clear;

  EncryptedLogin := Login;
  EncryptedPassword := Password;
  EncryptRijndael(EncryptedLogin, GetEncryptionKey());
  EncryptRijndael(EncryptedPassword, GetEncryptionKey());

  HTTPSender := THTTPSender.Create;
  if not HTTPSender.POST(
                          SkinSystemScriptAddress,
                          'login=' + HexEncode(EncryptedLogin) + '&password=' + HexEncode(EncryptedPassword) + '&action=download&image_type=' + ImageTypes[Integer(ImageType)],
                          Response
                         ) then
  begin
    FreeAndNil(HTTPSender);
    FreeAndNil(Response);
    FErrorReason := 'Не удалось выполнить запрос! Проверьте доступность адреса!';
    Exit(SKIN_SYSTEM_CONNECTION_ERROR);
  end;
  FreeAndNil(HTTPSender);

  ImageStream := TMemoryStream.Create;
  ImageStream.Clear;

  Result := ParseResponse(Response, ImageStream);
  FreeAndNil(Response);

  if Result = SKIN_SYSTEM_SUCCESS then
    ImageStream.SaveToFile(Destination);

  FreeAndNil(ImageStream);
end;

end.
