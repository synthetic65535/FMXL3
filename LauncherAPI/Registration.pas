unit Registration;

interface

uses
  System.JSON, SysUtils, Classes, HTTPUtils, HWID, Encryption, JSONUtils;

type
  TRegResponse = TJSONObject;
  PRegResponse = ^TRegResponse;

  // Структура с даными пользователя, которую передаём потоку регистрации:
  TRegData = record
    Login    : string;
    Password : string;
    HWID : string;
  end;

  // Статусные коды авторизации:
  REG_STATUS_CODE = (
    REG_STATUS_SUCCESS,          // Успешная регистрация
    REG_STATUS_UNKNOWN_ERROR,    // Неизвестная ошибка
    REG_STATUS_CONNECTION_ERROR, // Не удалось подключиться
    REG_STATUS_BAD_RESPONSE      // Не удалось раздекодить ответ
  );

  // Структура с результатом авторизации, возвращаемая в каллбэк:
  REG_STATUS = record
    StatusCode   : REG_STATUS_CODE;
    StatusString : string;
  end;

  // Событие авторизации:
  TOnReg = reference to procedure(const RegStatus: REG_STATUS);

  // Поток авторизации:
  TRegWorker = class(TThread)
    private
      FRegStatus        : REG_STATUS;
      FRegData          : TRegData;
      FRegResponse      : PRegResponse;
      FOnReg            : TOnReg;
      FRegScriptAddress : string;
      FEncryptionKey    : AnsiString;
    public
      property EncryptionKey: AnsiString read FEncryptionKey write FEncryptionKey;

      procedure RegisterPlayer(
                           const RegScriptAddress : string;       // Адрес скрипта авторизации
                           const RegData          : TRegData;     // Данные, отправляемые скрипту
                           out   RegResponse      : TRegResponse; // JSON-ответ от скрипта
                           OnReg                  : TOnReg        // Событие завершения авторизации
                          );
    protected
      procedure Execute; override;
  end;

implementation

{ TRegWorker }

procedure TRegWorker.RegisterPlayer(const RegScriptAddress: string; const RegData: TRegData;
  out RegResponse: TRegResponse; OnReg: TOnReg);
begin
  // Параметры авторизации:
  FRegScriptAddress := RegScriptAddress;
  FRegResponse      := @RegResponse;
  FRegData          := RegData;
  FOnReg            := OnReg;

  // Параметры потока:
  FreeOnTerminate := True;
  Start;
end;

procedure TRegWorker.Execute;
var
  HTTPSender: THTTPSender;
  Response: TStringStream;
  DecodedResponse: TBytes;
  Request: string;
  Status: string;
begin
  inherited;

  // Формируем запрос:
  Request := 'login=' + FRegData.Login + '&password=' + FRegData.Password;
  if FRegData.HWID <> '' then Request := Request + '&hwid=' + FRegData.HWID;

  // Отправляем запрос на сервер:
  HTTPSender := THTTPSender.Create;
  Response   := TStringStream.Create;
  HTTPSender.POST(FRegScriptAddress, Request, Response);

  if  HTTPSender.Status then
  begin
    // Декодируем запрос:
    DecodedResponse := Response.Encoding.Convert(
                                                  Response.Encoding.UTF8,
                                                  Response.Encoding.ANSI,
                                                  Response.Bytes,
                                                  0,
                                                  Length(Response.DataString)
                                                 );
    Response.Clear;
    Response.WriteData(DecodedResponse, Length(DecodedResponse));

    // Преобразовываем запрос в JSON:
    FRegResponse^ := JSONStringToJSONObject(Response.DataString);
    if FRegResponse^ <> nil then
    begin
      // Проверяем поле "status" в полученном JSON'е:
      if GetJSONStringValue(FRegResponse^, 'status', Status) then
      begin
        Status := LowerCase(Status);
        if Status = 'success' then
        begin
          FRegStatus.StatusCode := REG_STATUS_SUCCESS;
          FRegStatus.StatusString := 'Успешная регистрация!';
        end
        else
        begin
          FRegStatus.StatusCode := REG_STATUS_UNKNOWN_ERROR;

          // Получаем причину ошибки:
          if not GetJSONStringValue(FRegResponse^, 'reason', FRegStatus.StatusString) then
            FRegStatus.StatusString := 'Неизвестная ошибка!';
        end;
      end
      else
      begin
        FRegStatus.StatusCode := REG_STATUS_UNKNOWN_ERROR;
        FRegStatus.StatusString := 'JSON неизвестного формата! Проверьте настройки веб-части!';
      end;
    end
    else
    begin
      FRegStatus.StatusCode := REG_STATUS_BAD_RESPONSE;
      FRegStatus.StatusString := 'Не удалось преобразовать ответ от скрипта в JSON!';
    end;
  end
  else
  begin
    FRegStatus.StatusCode := REG_STATUS_CONNECTION_ERROR;
    FRegStatus.StatusString := 'Не удалось подключиться к серверу!';
  end;

  FreeAndNil(Response);
  FreeAndNil(HTTPSender);

  // Возвращаем результат:
  Synchronize(procedure()
  begin
    FOnReg(FRegStatus);
  end);
end;

end.
