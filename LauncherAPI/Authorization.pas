unit Authorization;

interface

uses
  System.JSON, SysUtils, Classes, HTTPUtils,
  Encryption, JSONUtils, CodepageAPI;

type
  TAuthResponse = TJSONObject;
  PAuthResponse = ^TAuthResponse;

  // Статусные коды авторизации:
  AUTH_STATUS_CODE = (
    AUTH_STATUS_SUCCESS,          // Успешная авторизация
    AUTH_STATUS_UNKNOWN_ERROR,    // Неизвестная ошибка
    AUTH_STATUS_CONNECTION_ERROR, // Не удалось подключиться
    AUTH_STATUS_BAD_RESPONSE      // Не удалось раздекодить ответ
  );

  // Структура с результатом авторизации, возвращаемая в каллбэк:
  AUTH_STATUS = record
    StatusCode   : AUTH_STATUS_CODE;
    StatusString : string;
    TokenString : string;
  end;

  // Событие авторизации:
  TOnAuth = reference to procedure(const AuthStatus: AUTH_STATUS);

  // Поток авторизации:
  TAuthWorker = class(TThread)
    private
      FAuthStatus: AUTH_STATUS;
      FAuthData: string;
      FAuthResponse: PAuthResponse;
      FOnAuth: TOnAuth;
      FAuthScriptAddress: string;
      FEncryptionKey: AnsiString;
      FPreAuth: Boolean;
    public
      property EncryptionKey: AnsiString read FEncryptionKey write FEncryptionKey;

      procedure Authorize(
                           const AuthScriptAddress : string;        // Адрес скрипта авторизации
                           const AuthData          : string;        // Данные, отправляемые скрипту
                           const PreAuth           : Boolean;       // Происходит ли получение токена
                           out   AuthResponse      : TAuthResponse; // JSON-ответ от скрипта
                           OnAuth                  : TOnAuth        // Событие завершения авторизации
                          );
    protected
      procedure Execute; override;
  end;

implementation

{ TAuthWorker }

procedure TAuthWorker.Authorize(const AuthScriptAddress: string; const AuthData: string; const PreAuth: Boolean;
  out AuthResponse: TAuthResponse; OnAuth: TOnAuth);
begin
  // Параметры авторизации:
  FAuthScriptAddress := AuthScriptAddress;
  FAuthResponse      := @AuthResponse;
  FAuthData          := AuthData;
  FPreAuth           := PreAuth;
  FOnAuth            := OnAuth;

  // Параметры потока:
  FreeOnTerminate := True;
  Start;
end;

procedure TAuthWorker.Execute;
var
  HTTPSender: THTTPSender;
  Response: TStringStream;
  Request: string;
  Status: string;
  Token: string;
  TempDataLength: Cardinal;
begin
  inherited;

  // Формируем запрос:
  Request := FAuthData;

  // Отправляем запрос на сервер:
  HTTPSender := THTTPSender.Create;
  Response   := TStringStream.Create;
  HTTPSender.POST(FAuthScriptAddress, Request, Response);

  if HTTPSender.Status and (Response.Size > 0) then
  begin
    // Расшифровываем запрос:
    TempDataLength := Response.Size;
    DecryptRijndael(Response.Memory, TempDataLength, FEncryptionKey);
    Response.Size := TempDataLength;
    UTF8Convert(Response);

    // Преобразовываем запрос в JSON:
    FAuthResponse^ := JSONStringToJSONObject(Response.DataString);
    if FAuthResponse^ <> nil then
    begin
      if FPreAuth then
        begin
        // Первый этап авторизации
        if GetJSONStringValue(FAuthResponse^, 'status', Status) then
          begin
            Status := LowerCase(Status);
            if Status = 'success' then
              begin
                if GetJSONStringValue(FAuthResponse^, 'token', Token) then
                begin
                  if Token <> '' then
                    begin
                      FAuthStatus.StatusCode := AUTH_STATUS_SUCCESS;
                      FauthStatus.StatusString := 'Токен успешно получен';
                      FauthStatus.TokenString := Token;
                    end
                    else
                    begin
                      FAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;
                      FAuthStatus.StatusString := 'Пустой токен!';
                      FauthStatus.TokenString := '';
                    end;
                end
                else
                begin
                  FAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;
                  FAuthStatus.StatusString := 'JSON неизвестного формата! Проверьте настройки веб-части!';
                  FauthStatus.TokenString := '';
                end;
              end
              else
              begin
                FAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;

                // Получаем причину ошибки:
                if not GetJSONStringValue(FAuthResponse^, 'reason', FAuthStatus.StatusString) then
                  begin
                  FAuthStatus.StatusString := 'Не удалось получить токен. Неизвестная ошибка!';
                  FauthStatus.TokenString := '';
                  end;
              end;
          end
          else
          begin
            FAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;
            FAuthStatus.StatusString := 'JSON неизвестного формата! Проверьте настройки веб-части!';
            FauthStatus.TokenString := '';
          end;
        end
        else
        begin
          // Второй этап авторизации
          // Проверяем поле "status" в полученном JSON'е:
          if GetJSONStringValue(FAuthResponse^, 'status', Status) then
          begin
            Status := LowerCase(Status);
            if Status = 'success' then
            begin
              FAuthStatus.StatusCode := AUTH_STATUS_SUCCESS;
              FauthStatus.StatusString := 'Успешная авторизация!';
            end
            else
            begin
              FAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;

              // Получаем причину ошибки:
              if not GetJSONStringValue(FAuthResponse^, 'reason', FAuthStatus.StatusString) then
                FAuthStatus.StatusString := 'Неизвестная ошибка!';
            end;
          end
          else
          begin
            FAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;
            FAuthStatus.StatusString := 'JSON неизвестного формата! Проверьте настройки веб-части!';
          end;
        end;
    end
    else
    begin
      FAuthStatus.StatusCode := AUTH_STATUS_BAD_RESPONSE;
      FAuthStatus.StatusString := 'Не удалось преобразовать ответ от скрипта в JSON!' + #13#10 +
                                  'Игрок, скачай новую версию лаунчера.' + #13#10 +
                                  'Администратор, проверь правильность ключа шифрования.';
    end;
  end
  else
  begin
    FAuthStatus.StatusCode := AUTH_STATUS_CONNECTION_ERROR;
    FAuthStatus.StatusString := 'Не удалось подключиться к серверу!' + #13#10 +
                                'Попробуйте снова через несколько минут.';
  end;

  FreeAndNil(Response);
  FreeAndNil(HTTPSender);

  // Возвращаем результат:
  Synchronize(procedure()
  begin
    FOnAuth(FAuthStatus);
  end);
end;

end.
