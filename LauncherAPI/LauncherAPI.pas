unit LauncherAPI;

interface

uses
  Windows, SysUtils, Classes, System.NetEncoding, System.JSON, JSONUtils,
  Authorization, Registration, SkinSystem, FilesValidation, MinecraftLauncher,
  UserInformation, JavaInformation, ServersInformation, LauncherInformation,
  Encryption, HTTPUtils, HTTPMultiLoader, StringsAPI, JNIWrapper, HWID;

type
  QUERY_STATUS_CODE = (
    QUERY_STATUS_SUCCESS,
    QUERY_STATUS_DOWNLOAD_ERROR,
    QUERY_STATUS_UNKNOWN_FORMAT,
    QUERY_STATUS_DECODING_ERROR
  );

  QUERY_STATUS = record
    StatusCode   : QUERY_STATUS_CODE;
    StatusString : string;
  end;

  TOnQuery    = reference to procedure(ClientNumber: Integer; QueryStatus: QUERY_STATUS);
  TOnValidate = reference to procedure(ClientNumber: Integer; ClientValidationStatus, JavaValidationStatus: VALIDATION_STATUS);

  TMultiLoaderDownloadInfo = record
    SummaryDownloadInfo: TSummaryDownloadInfo;
    CurrentDownloadInfo: TDownloadInfo;
    HTTPSender: THTTPSender;
  end;
  TOnUpdate = reference to procedure(ClientNumber: Integer; const DownloadInfo: TMultiLoaderDownloadInfo);

  TLauncherAPI = class
    private const
      // Адреса скриптов и папок относительно FServerBaseAddress:
      RegScriptName        : string = 'reg.php';
      AuthScriptName       : string = 'auth.php';
      SkinSystemScriptName : string = 'skinsUtils.php';
    private
      // Глобальные настройки:
      FBaseFolder        : string; // Рабочая папка на локальном компьютере
      FServerBaseAddress : string; // Адрес рабочей папки на сервере
      FServerBaseAddressDownload : string; // Адрес рабочей папки на сервере с клиентами 
      FEncryptionKey     : AnsiString; // Ключ шифрования

      // Заполняются при авторизации:
      FLauncherInfo : TLauncherInfo;
      FUserInfo     : TUserInfo;
      FClients      : TClients;
      FJavaInfo     : TJavaInfo;

      // Регистрация:
      FRegResponse : TRegResponse;
      FRegWorker   : TRegWorker;

      // Авторизация:
      FAuthResponse : TAuthResponse;
      FPreAuthResponse : TAuthResponse;
      FPreAuthWorker : TAuthWorker;
      FAuthWorker   : TAuthWorker;
      FIsAuthorized : Boolean;

      // Система скинов:
      FSkinSystem: TSkinSystemWrapper;

      function EncryptData(const Data: string): string;
      function QueryValidFilesJSON(const Link: string; const FilesValidator: TFilesValidator): QUERY_STATUS_CODE;
      procedure QueryValidFilesThreadProc(ClientNumber: Integer; out QueryStatus: QUERY_STATUS);
      procedure StartDownloader(const DownloadList: TDownloadList; const MultiLoader: THTTPMultiLoader; ClientNumber: Integer; Multithreading: Boolean; OnUpdate: TOnUpdate);
      procedure MergeDownloadLists(const List1, List2, ResultList: TDownloadList);
    public
      property LocalWorkingFolder: string read FBaseFolder write FBaseFolder;
      property ServerWorkingFolder: string read FServerBaseAddress write FServerBaseAddress;
      property ServerWorkingFolderDownload: string read FServerBaseAddressDownload write FServerBaseAddressDownload;
      property EncryptionKey: AnsiString read FEncryptionKey write FEncryptionKey;

      property IsAuthorized: Boolean read FIsAuthorized;

      property LauncherInfo : TLauncherInfo read FLauncherInfo;
      property UserInfo     : TUserInfo     read FUserInfo;
      property Clients      : TClients      read FClients;
      property JavaInfo     : TJavaInfo     read FJavaInfo;

      property SkinSystem   : TSkinSystemWrapper read FSkinSystem;

      constructor Create(const LocalBaseFolder, ServerBaseFolder, ServerBaseFolderdownload: string);
      destructor Destroy; override;

      // Авторизация, работа с файлами, запуск клиента:
      procedure RegisterPlayer(const Login, Password: string; SendHWID: Boolean; OnReg: TOnReg);
      procedure Authorize(const Login, Password: string; SendHWID: Boolean; OnAuth: TOnAuth);
      procedure GetValidFilesList(ClientNumber: Integer; OnQuery: TOnQuery);
      function ValidateClient(ClientNumber: Integer; Multithreading: Boolean; OnValidate: TOnValidate): Boolean;
      function UpdateClient(ClientNumber: Integer; Multithreading: Boolean; OnUpdate: TOnUpdate): Boolean;
      function LaunchClient(ClientNumber, RAM: Integer; OptimizeJVM, ExperimentalOptimization: Boolean): JNI_RETURN_VALUES;

      // Проверка клиента во время игры:
      procedure StartInGameChecking(ClientNumber: Integer; OnFilesMismatching: TOnFilesMismatching);
      procedure StopInGameChecking(ClientNumber: Integer);

      // Система скинов:
      function SetupSkin (const Login, Password, SkinPath: string): SKIN_SYSTEM_STATUS;
      function SetupCloak(const Login, Password, CloakPath: string): SKIN_SYSTEM_STATUS;
      function DeleteSkin (const Login, Password: string): SKIN_SYSTEM_STATUS;
      function DeleteCloak(const Login, Password: string): SKIN_SYSTEM_STATUS;
      function DownloadSkin (const Login, Password, Destination: string): SKIN_SYSTEM_STATUS;
      function DownloadCloak(const Login, Password, Destination: string): SKIN_SYSTEM_STATUS;

      // Мониторинг:
      procedure StartMonitoring(Interval: Integer; OnMonitoring: TOnMonitoring);
      procedure StopMonitoring;

      // Глобальная очистка, отмена всех операций:
      procedure Deauthorize;
      procedure Clear;
  end;

implementation

{ TLauncherAPI }

constructor TLauncherAPI.Create(const LocalBaseFolder, ServerBaseFolder, ServerBaseFolderDownload: string);
begin
  FEncryptionKey := '';

  FBaseFolder        := LocalBaseFolder;
  FServerBaseAddress := ServerBaseFolder;
  FServerBaseAddressDownload := ServerBaseFolderDownload;

  FIsAuthorized := False;

  FLauncherInfo := TLauncherInfo.Create;
  FUserInfo     := TUserInfo.Create;
  FClients      := TClients.Create;
  FJavaInfo     := TJavaInfo.Create;
  FSkinSystem   := TSkinSystemWrapper.Create;
end;

destructor TLauncherAPI.Destroy;
var
  I: Integer;
  DownloadingEvents: array of THandle;
begin
  if FClients.Count > 0 then
  begin
    // Отменяем все загрузки:
    SetLength(DownloadingEvents, FClients.Count);
    for I := 0 to FClients.Count - 1 do
    begin
      FClients.ClientsArray[I].MultiLoader.Cancel;
      DownloadingEvents[I] := FClients.ClientsArray[I].MultiLoader.DownloadingEvent;
    end;

    // Ждём, пока все загрузки завершатся, чтобы безопасно освободить ресурсы:
    WaitForMultipleObjects(FClients.Count, @DownloadingEvents[0], True, INFINITE);
    SetLength(DownloadingEvents, 0);
  end;

  FreeAndNil(FLauncherInfo);
  FreeAndNil(FUserInfo);
  FreeAndNil(FClients);
  FreeAndNil(FJavaInfo);
  FreeAndNil(FSkinSystem);

  inherited;
end;

function TLauncherAPI.EncryptData(const Data: string): string;
var
  S: AnsiString;
begin
  S := Data;
  EncryptRijndael(S, FEncryptionKey);
  Result := S;
end;

procedure TLauncherAPI.RegisterPlayer(const Login, Password: string;
  SendHWID: Boolean; OnReg: TOnReg);
var
  RegData: string;
begin
  if SendHWID then
  begin
    RegData := EncryptData('{' +
    '"action":"auth",' +
    '"login":"' + Login + '",' +
    '"password":"' + HexEncode(Password) + '",' +
    '"hwid":"' + GetHWID() +
    '"}');
  end else
    begin
      RegData := EncryptData('{' +
      '"action":"auth",' +
      '"login":"' + Login + '",' +
      '"password":"' + Password +
      '"}');
    end;

  // Создаём поток регистрации:
  FRegWorker := TRegWorker.Create(True);
  FRegWorker.EncryptionKey := FEncryptionKey;
  FRegWorker.RegisterPlayer(
                             FServerBaseAddress + '/' + RegScriptName,
                             RegData,
                             FRegResponse,
                             procedure(const RegStatus: REG_STATUS)
                             begin
                               if Assigned(OnReg) then OnReg(RegStatus);
                             end
                            );
end;


procedure TLauncherAPI.Authorize(const Login, Password: string;
  SendHWID: Boolean; OnAuth: TOnAuth);
var
  PreAuthData: string;
  GlobalPreAuthStatus: AUTH_STATUS;

  AuthData: string;
  GlobalAuthStatus: AUTH_STATUS;
begin
  PreAuthData := EncryptData('{' +
    '"action":"preauth",' +
    '"login":"' + Login + '",' +
    '"password":"' + HexEncode(Password) +
    '"}');

  // Создаём поток первого этапа авторизации:
  FPreAuthWorker := TAuthWorker.Create(True);
  FPreAuthWorker.EncryptionKey := FEncryptionKey;
  FPreAuthWorker.Authorize(
    FServerBaseAddress + '/' + AuthScriptName,
    PreAuthData,
    true, // Первый этап
    FPreAuthResponse,
    procedure(const PreAuthStatus: AUTH_STATUS)
    begin
     if PreAuthStatus.StatusCode = AUTH_STATUS_SUCCESS then
     begin
      if SendHWID then
      begin
        AuthData := EncryptData('{' +
        '"action":"auth",' +
        '"login":"' + Login + '",' +
        '"password":"' + HexEncode(Password) + '",' +
        '"hwid":"' + GetHWID() + '",' +
        '"token":"' + PreAuthStatus.TokenString +
        '"}');
      end else
        begin
          AuthData := EncryptData('{' +
          '"action":"auth",' +
          '"login":"' + Login + '",' +
          '"password":"' + HexEncode(Password) + '",' +
          '"token":"' + PreAuthStatus.TokenString +
          '"}');
        end;

      // Создаём поток второго этапа авторизации:
      FAuthWorker := TAuthWorker.Create(True);
      FAuthWorker.EncryptionKey := FEncryptionKey;
      FAuthWorker.Authorize(
        FServerBaseAddress + '/' + AuthScriptName,
        AuthData,
        false, // Второй этап
        FAuthResponse,
        procedure(const AuthStatus: AUTH_STATUS)
        var
         ServersInfo: TJSONObject;
        begin
         if AuthStatus.StatusCode = AUTH_STATUS_SUCCESS then
         begin
           // Получаем информацию о лаунчере:
           if not FLauncherInfo.ExtractLauncherInfo(FAuthResponse) then
           begin
             GlobalAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;
             GlobalAuthStatus.StatusString := 'Не удалось получить информацию о лаунчере!';
             if Assigned(OnAuth) then OnAuth(GlobalAuthStatus);
             FreeAndNil(FAuthResponse);
             Exit;
           end;

           // Получаем информацию о пользователе:
           if not FUserInfo.ExtractUserInfo(FAuthResponse) then
           begin
             GlobalAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;
             GlobalAuthStatus.StatusString := 'Не удалось получить авторизационные данные игрока!';
             if Assigned(OnAuth) then OnAuth(GlobalAuthStatus);
             FreeAndNil(FAuthResponse);
             Exit;
           end;

           ServersInfo := GetJSONObjectValue(FAuthResponse, 'servers_info');

           // Получаем информацию о серверах:
           if not FClients.ExtractServersInfo(ServersInfo, FServerBaseAddress) then
           begin
             GlobalAuthStatus.StatusCode := AUTH_STATUS_UNKNOWN_ERROR;
             GlobalAuthStatus.StatusString := 'Не удалось получить информацию о серверах!';
             if Assigned(OnAuth) then OnAuth(GlobalAuthStatus);
             FreeAndNil(FAuthResponse);
             Exit;
           end;

           // Получаем информацию о джаве:
           FJavaInfo.ExtractJavaInfo(ServersInfo);

           FIsAuthorized := True;

           // Успешная авторизация
           if Assigned(OnAuth) then OnAuth(AuthStatus);
         end
         else
         begin
           // Не удался второй этап авторизации
           if Assigned(OnAuth) then OnAuth(AuthStatus);
         end;

         FreeAndNil(FAuthResponse);
        end
        );
     end
     else
     begin
       // Не удался первый этап авторизации
       if Assigned(OnAuth) then OnAuth(PreAuthStatus);
     end;

     FreeAndNil(FPreAuthResponse);
    end
    );
end;



function TLauncherAPI.QueryValidFilesJSON(const Link: string; const FilesValidator: TFilesValidator): QUERY_STATUS_CODE;
var
  HTTPSender: THTTPSender;
  Response: TStringStream;
  ValidFilesJSON: TJSONObject;
  ValidFilesJSONArray: TJSONArray;
  TempDataLength: Cardinal;
begin
  HTTPSender := THTTPSender.Create;
  Response := TStringStream.Create;
  HTTPSender.GET(Link, Response);

  if HTTPSender.Status and (Response.Size > 0) then
  begin
    TempDataLength := Response.Size;
    DecryptRijndael(Response.Memory, TempDataLength, FEncryptionKey);
    Response.Size := TempDataLength;
    ValidFilesJSON := JSONStringToJSONObject(Response.DataString);
    if ValidFilesJSON <> nil then
    begin
      if GetJSONArrayValue(ValidFilesJSON, 'files', ValidFilesJSONArray) then
      begin
        FilesValidator.ExtractValidFilesInfo(ValidFilesJSONArray);
        Result := QUERY_STATUS_SUCCESS;
      end
      else
      begin
        Result := QUERY_STATUS_UNKNOWN_FORMAT;
      end;
      FreeAndNil(ValidFilesJSON);
    end
    else
    begin
      Result := QUERY_STATUS_DECODING_ERROR;
    end;
  end
  else
  begin
    Result := QUERY_STATUS_DOWNLOAD_ERROR;
  end;
end;


procedure TLauncherAPI.QueryValidFilesThreadProc(ClientNumber: Integer; out QueryStatus: QUERY_STATUS);
var
  DownloadEvents: packed record
    Client : THandle;
    Java   : THandle;
  end;
  ClientQueryStatus, JavaQueryStatus: QUERY_STATUS_CODE;
  ClientLink, JavaLink: string;
begin
  DownloadEvents.Client := CreateEvent(nil, True, True, nil);
  DownloadEvents.Java   := CreateEvent(nil, True, True, nil);

  // Скачиваем список файлов выбранного клиента:
  ClientLink := FixSlashes(FServerBaseAddressDownload + '/' + FClients.ClientsArray[ClientNumber].ServerInfo.ClientFolder + '.json', True);
  ResetEvent(DownloadEvents.Client);
  TThread.CreateAnonymousThread(procedure()
  begin
    ClientQueryStatus := QueryValidFilesJSON(ClientLink, FClients.ClientsArray[ClientNumber].FilesValidator);
    SetEvent(DownloadEvents.Client);
  end).Start;

  // Если надо - скачиваем список файлов джавы:
  if not FJavaInfo.ExternalJava then
  begin
    JavaLink := FixSlashes(FServerBaseAddressDownload + '/' + FJavaInfo.JavaParameters.JavaFolder + '.json', True);
    ResetEvent(DownloadEvents.Java);
    TThread.CreateAnonymousThread(procedure()
    begin
      JavaQueryStatus := QueryValidFilesJSON(JavaLink, FJavaInfo.FilesValidator);
      SetEvent(DownloadEvents.Java);
    end).Start;
  end;

  WaitForMultipleObjects(2, @DownloadEvents, TRUE, INFINITE);
  
  // Возможно скачивание со второго сайта не удалось, пробуем скачать с первого
  
  // Client
  if ClientQueryStatus <> QUERY_STATUS_SUCCESS then
  begin
    // Скачиваем список файлов выбранного клиента:
    ClientLink := FixSlashes(FServerBaseAddress + '/' + FClients.ClientsArray[ClientNumber].ServerInfo.ClientFolder + '.json', True);
    ResetEvent(DownloadEvents.Client);
    TThread.CreateAnonymousThread(procedure()
    begin
      ClientQueryStatus := QueryValidFilesJSON(ClientLink, FClients.ClientsArray[ClientNumber].FilesValidator);
      SetEvent(DownloadEvents.Client);
    end).Start;
  end;
  
  // Java
  if JavaQueryStatus <> QUERY_STATUS_SUCCESS then
  begin
    // Если надо - скачиваем список файлов джавы:
    if not FJavaInfo.ExternalJava then
    begin
      JavaLink := FixSlashes(FServerBaseAddress + '/' + FJavaInfo.JavaParameters.JavaFolder + '.json', True);
      ResetEvent(DownloadEvents.Java);
      TThread.CreateAnonymousThread(procedure()
      begin
        JavaQueryStatus := QueryValidFilesJSON(JavaLink, FJavaInfo.FilesValidator);
        SetEvent(DownloadEvents.Java);
      end).Start;
  end;
  end;
  
  WaitForMultipleObjects(2, @DownloadEvents, TRUE, INFINITE);


  CloseHandle(DownloadEvents.Client);
  CloseHandle(DownloadEvents.Java);

  if ClientQueryStatus <> QUERY_STATUS_SUCCESS then
  begin
    QueryStatus.StatusCode := ClientQueryStatus;
    case ClientQueryStatus of
      QUERY_STATUS_DOWNLOAD_ERROR: QueryStatus.StatusString := 'Не удалось загрузить список файлов клиента!' + #13#10 + ClientLink + #13#10 + 'Попробуйте снова через несколько минут.';
      QUERY_STATUS_UNKNOWN_FORMAT: QueryStatus.StatusString := 'Неизвестный формат списка файлов клиента!' + #13#10 + ClientLink;
      QUERY_STATUS_DECODING_ERROR: QueryStatus.StatusString := 'Не получилось декодировать список файлов клиента!' + #13#10 + ClientLink + #13#10 + 'Попробуйте снова через несколько минут.'; 
    end;
    Exit;
  end;

  if not FJavaInfo.ExternalJava and (JavaQueryStatus <> QUERY_STATUS_SUCCESS) then
  begin
    QueryStatus.StatusCode := JavaQueryStatus;
    case JavaQueryStatus of
      QUERY_STATUS_DOWNLOAD_ERROR: QueryStatus.StatusString := 'Не удалось загрузить список файлов Java!' + #13#10 + JavaLink + #13#10 + 'Попробуйте снова через несколько минут.';
      QUERY_STATUS_UNKNOWN_FORMAT: QueryStatus.StatusString := 'Неизвестный формат списка файлов Java!' + #13#10 + JavaLink;
      QUERY_STATUS_DECODING_ERROR: QueryStatus.StatusString := 'Не получилось декодировать список файлов Java!' + #13#10 + JavaLink + #13#10 + 'Попробуйте снова через несколько минут.';
    end;
    Exit;
  end;

  QueryStatus.StatusCode := QUERY_STATUS_SUCCESS;
  QueryStatus.StatusString := 'Списки файлов успешно получены!';
end;


procedure TLauncherAPI.GetValidFilesList(ClientNumber: Integer; OnQuery: TOnQuery);
var
  QueryThread: TThread;
begin
  if (ClientNumber < 0) or (ClientNumber >= FClients.Count) then Exit;

  QueryThread := TThread.CreateAnonymousThread(procedure()
  var
    QueryStatus: QUERY_STATUS;
  begin
    QueryValidFilesThreadProc(ClientNumber, QueryStatus);

    TThread.Synchronize(QueryThread, procedure()
    begin
      if Assigned(OnQuery) then OnQuery(ClientNumber, QueryStatus);
    end);
  end);
  QueryThread.FreeOnTerminate := True;
  QueryThread.Start;
end;


function TLauncherAPI.ValidateClient(ClientNumber: Integer; Multithreading: Boolean; OnValidate: TOnValidate): Boolean;
var
  ValidationThread: TThread;

begin
  if (ClientNumber < 0) or (ClientNumber >= FClients.Count) then Exit(False);
  if FClients.ClientsArray[ClientNumber].GetValidationStatus then Exit(False);

  FClients.ClientsArray[ClientNumber].SetValidationStatus(True);

  ValidationThread := TThread.CreateAnonymousThread(procedure()
  var
    RelativeClientWorkingFolder, RelativeJavaWorkingFolder: string;
    I: Integer;
    ClientValidationStatus, JavaValidationStatus: VALIDATION_STATUS;
  begin
    RelativeClientWorkingFolder := FixSlashes(FClients.ClientsArray[ClientNumber].ServerInfo.ClientFolder);
    
    ClientValidationStatus := FClients.ClientsArray[ClientNumber].FilesValidator.Validate(FBaseFolder, RelativeClientWorkingFolder, Multithreading);

    JavaValidationStatus := VALIDATION_STATUS_SUCCESS;
    if not (FJavaInfo.GetValidationStatus or FJavaInfo.ExternalJava) then
    begin
      FJavaInfo.SetValidationStatus(True, ClientNumber);
      RelativeJavaWorkingFolder := FixSlashes(FJavaInfo.JavaParameters.JavaFolder);
      JavaValidationStatus := FJavaInfo.FilesValidator.Validate(FBaseFolder, RelativeJavaWorkingFolder, Multithreading);
    end;

    TThread.Synchronize(ValidationThread, procedure()
    begin
      FClients.ClientsArray[ClientNumber].SetValidationStatus(False);
      if FJavaInfo.GetValidationStatus and (FJavaInfo.GetValidationClientID = ClientNumber) then
      begin
        FJavaInfo.SetValidationStatus(False, -1);
      end;

      if Assigned(OnValidate) then OnValidate(ClientNumber, ClientValidationStatus, JavaValidationStatus);
    end);
  end);
  ValidationThread.FreeOnTerminate := True;
  ValidationThread.Start;

  Result := True;
end;




procedure TLauncherAPI.StartDownloader(const DownloadList: TDownloadList;
  const MultiLoader: THTTPMultiLoader; ClientNumber: Integer; Multithreading: Boolean; OnUpdate: TOnUpdate);
begin
  MultiLoader.DownloadList(
                            FBaseFolder,
                            FServerBaseAddressDownload,
                            DownloadList,
                            MultiThreading,
                            procedure(
                                       const SummaryDownloadInfo: TSummaryDownloadInfo;
                                       const CurrentDownloadInfo: TDownloadInfo;
                                       const HTTPSender: THTTPSender
                                      )
                            var
                              DownloadInfo: TMultiLoaderDownloadInfo;
                            begin
                              DownloadInfo.SummaryDownloadInfo := SummaryDownloadInfo;
                              DownloadInfo.CurrentDownloadInfo := CurrentDownloadInfo;
                              DownloadInfo.HTTPSender := HTTPSender;

                              // Когда всё загрузили - снимаем флажок загрузки и очищаем списки файлов:
                              if DownloadInfo.SummaryDownloadInfo.IsFinished then
                              begin
                                FClients.ClientsArray[ClientNumber].SetValidationStatus(False);
                                FClients.ClientsArray[ClientNumber].FilesValidator.ClearFilesLists;
                                if FJavaInfo.GetValidationStatus and (FJavaInfo.GetValidationClientID = ClientNumber) then
                                begin
                                  FJavaInfo.SetValidationStatus(False, -1);
                                  FJavaInfo.FilesValidator.ClearFilesLists;
                                end;
                              end;

                              if Assigned(OnUpdate) then OnUpdate(ClientNumber, DownloadInfo);
                            end
                           );
end;




procedure TLauncherAPI.MergeDownloadLists(const List1, List2,
  ResultList: TDownloadList);
var
  I: Integer;
begin
  ResultList.Clear;

  if List1 <> nil then if List1.Count > 0 then
  begin
    for I := 0 to List1.Count - 1 do
      ResultList.Add(List1[I]);
  end;

  if List2 <> nil then if List2.Count > 0 then
  begin
    for I := 0 to List2.Count - 1 do
      ResultList.Add(List2[I]);
  end;
end;


function TLauncherAPI.UpdateClient(ClientNumber: Integer; Multithreading: Boolean; OnUpdate: TOnUpdate): Boolean;
var
  Client: TMinecraftLauncher;
  DownloadList: TDownloadList;
begin
  Result := False;
  if (ClientNumber < 0) or (ClientNumber >= FClients.Count) then Exit;

  Client := FClients.ClientsArray[ClientNumber];
  if Client.GetValidationStatus then Exit;
  Client.SetValidationStatus(True);

  // Проверяем, нужно ли загружать джаву, и, в зависимости от этого, формируем список файлов на загрузку:
  DownloadList := TDownloadList.Create;
  DownloadList.Clear;
  if not (FJavaInfo.GetValidationStatus or FJavaInfo.ExternalJava) then
  begin
    FJavaInfo.SetValidationStatus(True, ClientNumber);
    MergeDownloadLists(TDownloadList(Client.FilesValidator.AbsentFiles), TDownloadList(FJavaInfo.FilesValidator.AbsentFiles), DownloadList);
  end
  else
  begin
    MergeDownloadLists(TDownloadList(Client.FilesValidator.AbsentFiles), nil, DownloadList);
  end;

  StartDownloader(
                   DownloadList,
                   Client.MultiLoader,
                   ClientNumber,
                   MultiThreading,
                   OnUpdate
                  );

  Result := True;
  FreeAndNil(DownloadList);
end;


function TLauncherAPI.LaunchClient(ClientNumber, RAM: Integer; OptimizeJVM, ExperimentalOptimization: Boolean): JNI_RETURN_VALUES;
begin
  if (ClientNumber < 0) or (ClientNumber >= FClients.Count) then Exit(JNIWRAPPER_UNKNOWN_ERROR);
  Result := FClients.ClientsArray[ClientNumber].Launch(FBaseFolder, FUserInfo, FJavaInfo, RAM, OptimizeJVM, ExperimentalOptimization);
end;



procedure TLauncherAPI.StartInGameChecking(ClientNumber: Integer;
  OnFilesMismatching: TOnFilesMismatching);
var
  Client: TMinecraftLauncher;
begin
  if (ClientNumber < 0) or (ClientNumber >= FClients.Count) then Exit;
  Client := FClients.ClientsArray[ClientNumber];
  Client.FilesValidator.StartFoldersWatching(FBaseFolder + '\' + Client.ServerInfo.ClientFolder, OnFilesMismatching);

  if not FJavaInfo.ExternalJava then
    FJavaInfo.FilesValidator.StartFoldersWatching(FBaseFolder + '\' + FJavaInfo.JavaParameters.JavaFolder, OnFilesMismatching);
end;

procedure TLauncherAPI.StopInGameChecking(ClientNumber: Integer);
var
  Client: TMinecraftLauncher;
begin
  if (ClientNumber < 0) or (ClientNumber >= FClients.Count) then Exit;
  Client := FClients.ClientsArray[ClientNumber];
  Client.FilesValidator.StopFoldersWatching;

  if not FJavaInfo.ExternalJava then
    FJavaInfo.FilesValidator.StopFoldersWatching;
end;



function TLauncherAPI.SetupSkin(const Login, Password,
  SkinPath: string): SKIN_SYSTEM_STATUS;
begin
  Result := FSkinSystem.SetupImage(FServerBaseAddress + '/' + SkinSystemScriptName, Login, Password, SkinPath, IMAGE_SKIN, FUserInfo);
end;

function TLauncherAPI.SetupCloak(const Login, Password,
  CloakPath: string): SKIN_SYSTEM_STATUS;
begin
  Result := FSkinSystem.SetupImage(FServerBaseAddress + '/' + SkinSystemScriptName, Login, Password, CloakPath, IMAGE_CLOAK, FUserInfo);
end;



function TLauncherAPI.DeleteSkin(const Login,
  Password: string): SKIN_SYSTEM_STATUS;
begin
  Result := FSkinSystem.DeleteImage(FServerBaseAddress + '/' + SkinSystemScriptName, Login, Password, IMAGE_SKIN, FUserInfo);
end;

function TLauncherAPI.DeleteCloak(const Login,
  Password: string): SKIN_SYSTEM_STATUS;
begin
  Result := FSkinSystem.DeleteImage(FServerBaseAddress + '/' + SkinSystemScriptName, Login, Password, IMAGE_CLOAK, FUserInfo);
end;



function TLauncherAPI.DownloadSkin(const Login, Password,
  Destination: string): SKIN_SYSTEM_STATUS;
begin
  Result := FSkinSystem.DownloadImage(FServerBaseAddress + '/' + SkinSystemScriptName, Destination, Login, Password, IMAGE_SKIN);
end;


function TLauncherAPI.DownloadCloak(const Login, Password,
  Destination: string): SKIN_SYSTEM_STATUS;
begin
  Result := FSkinSystem.DownloadImage(FServerBaseAddress + '/' + SkinSystemScriptName, Destination, Login, Password, IMAGE_CLOAK);
end;



procedure TLauncherAPI.StartMonitoring(Interval: Integer; OnMonitoring: TOnMonitoring);
var
  I: Integer;
begin
  for I := 0 to FClients.Count - 1 do
  begin
    FClients.ClientsArray[I].StartMonitoring(I, Interval, OnMonitoring);
  end;
end;

procedure TLauncherAPI.StopMonitoring;
var
  I: Integer;
begin
  for I := 0 to FClients.Count - 1 do
  begin
    FClients.ClientsArray[I].StopMonitoring;
  end;
end;


procedure TLauncherAPI.Deauthorize;
begin
  Clear;
end;

procedure TLauncherAPI.Clear;
begin
  FIsAuthorized := False;
  FLauncherInfo.Clear;
  FClients.Clear;
  FUserInfo.Clear;
  FJavaInfo.Clear;
end;

end.
