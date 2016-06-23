unit MinecraftLauncher;

interface

uses
  Windows, Classes, SysUtils,
  System.JSON, System.Threading, FMX.Graphics,
  CodepageAPI, StringsAPI, FileAPI, JSONUtils, TimeManagement,
  DownloadHelper, HTTPUtils, HTTPMultiLoader,
  JavaInformation, UserInformation, FilesValidation, JNIWrapper, ServerQuery,
  AuxUtils, CPUIDInfo;

type
  TClientInfo = TJSONObject;
  PClientInfo = ^TClientInfo;
  TFMXBitmap  = FMX.Graphics.TBitmap;

  TStringArray = array of string;


  TServerInfo = record
    // Название и описание:
    Name : string;
    Info : string;

    // Сетевые параметры:
    IP   : string;
    Port : string;

    // Файлы и папки:
    ClientFolder  : string; // Базовая папка, относительно которой берутся все остальные
    JarFolders    : TStringArray;
    NativesFolder : string;
    AssetsFolder  : string;
    AssetIndex    : string;

    // Параметры запуска:
    Version   : string;
    MainClass : string;
    Arguments : string;
  end;

  TOnMonitoring = reference to procedure(ServerNumber: Integer; const MonitoringInfo: TMonitoringInfo);

  TMinecraftLauncher = class
    private
      FValidationStatusCriticalSection : _RTL_CRITICAL_SECTION;
      FValidationStatus : Boolean;
      FHasPreview       : Boolean;
      FServerInfo       : TServerInfo;
      FPreviewBitmap    : TFMXBitmap;
      FFilesValidator   : TFilesValidator;
      FMultiLoader      : THTTPMultiLoader;
      FMonitoringStatus : Boolean;
      function InsertParams(const ParametrizedString, BaseFolder: string; const UserInfo: TUserInfo; const JavaInfo: TJavaInfo): string;
    public
      property ServerInfo: TServerInfo read FServerInfo;
      property PreviewBitmap: TFMXBitmap read FPreviewBitmap;
      property FilesValidator: TFilesValidator read FFilesValidator;
      property MultiLoader: THTTPMultiLoader read FMultiLoader;
      property HasPreview: Boolean read FHasPreview;

      constructor Create;
      destructor Destroy; override;

      procedure ExtractClientInfo(const ClientInfo: TClientInfo; const HostBaseFolder: string);
      //procedure LoadInternalPreview;

      procedure SetValidationStatus(Status: Boolean);
      function GetValidationStatus: Boolean;

      procedure FillParams(const BaseFolder: string; const UserInfo: TUserInfo; const JavaInfo: TJavaInfo);
      function Launch(
                       const BaseFolder: string;
                       const UserInfo: TUserInfo;
                       const JavaInfo: TJavaInfo;
                       RAM: Integer;
                       OptimizeJVM: Boolean;
                       ExperimentalOptimization: Boolean
                      ): JNI_RETURN_VALUES;

      procedure Clear;

      procedure StartMonitoring(ServerNumber, Interval: Integer; OnMonitoring: TOnMonitoring);
      procedure StopMonitoring;
  end;

implementation

{ TMinecraftLauncher }


constructor TMinecraftLauncher.Create;
begin
  FPreviewBitmap := TFMXBitmap.Create;
  FFilesValidator := TFilesValidator.Create;
  FMultiLoader := THTTPMultiLoader.Create;
  InitializeCriticalSection(FValidationStatusCriticalSection);
  Clear;
end;

destructor TMinecraftLauncher.Destroy;
begin
  StopMonitoring;
  FMultiLoader.Cancel;
  FMultiLoader.WaitForDownloadComplete;
  Clear;
  DeleteCriticalSection(FValidationStatusCriticalSection);
  FreeAndNil(FPreviewBitmap);
  FreeAndNil(FFilesValidator);
  FreeAndNil(FMultiLoader);
  inherited;
end;


procedure TMinecraftLauncher.ExtractClientInfo(const ClientInfo: TClientInfo; const HostBaseFolder: string);
var
  JarFoldersArray, CheckedFoldersArray: TJSONArray;
  PreviewLink: string;
  DownloadEvent: THandle;
begin
  Clear;
  if ClientInfo = nil then Exit;

  // Ставим на загрузку превьюшку, пока будем парсить JSON:
  DownloadEvent := CreateEvent(nil, True, False, nil);
  if GetJSONStringValue(ClientInfo, 'preview', PreviewLink) then
  begin
    TThread.CreateAnonymousThread(procedure()
    begin
    {
      if not DownloadImage(HostBaseFolder + '/' + PreviewLink, FPreviewBitmap) then
        LoadInternalPreview;
    }
      FHasPreview := DownloadImage(HostBaseFolder + '/' + PreviewLink, FPreviewBitmap);
      SetEvent(DownloadEvent);
    end).Start;
  end
  else
  begin
    //LoadInternalPreview;
    FHasPreview := False;
    SetEvent(DownloadEvent);
  end;

  with FServerInfo do
  begin
    // Получаем параметры клиента:
    Name  := GetJSONStringValue(ClientInfo, 'name');
    Info  := GetJSONStringValue(ClientInfo, 'info');
    IP    := GetJSONStringValue(ClientInfo, 'ip');
    Port  := GetJSONStringValue(ClientInfo, 'port');
    ClientFolder  := FixSlashes(GetJSONStringValue(ClientInfo, 'client_folder'));
    NativesFolder := FixSlashes(GetJSONStringValue(ClientInfo, 'natives_path'));
    AssetsFolder  := FixSlashes(GetJSONStringValue(ClientInfo, 'assets_path'));
    AssetIndex    := GetJSONStringValue(ClientInfo, 'asset_index');
    Version       := GetJSONStringValue(ClientInfo, 'version');
    MainClass     := GetJSONStringValue(ClientInfo, 'main_class');
    Arguments     := GetJSONStringValue(ClientInfo, 'arguments');
  end;

  // Получаем список папок с джарниками (относительно ClientFolder):
  JarFoldersArray := GetJSONArrayValue(ClientInfo, 'jars');
  if JarFoldersArray <> nil then
  begin
    if JarFoldersArray.Count > 0 then
    begin
      SetLength(FServerInfo.JarFolders, JarFoldersArray.Count);
      TParallel.&For(0, JarFoldersArray.Count - 1, procedure(I: Integer)
      begin
        FServerInfo.JarFolders[I] := GetJSONStringValue(GetJSONArrayElement(JarFoldersArray, I), 'name');
      end);
    end;
  end;

  // Получаем список файлов и папок на проверку:
  CheckedFoldersArray := GetJSONArrayValue(ClientInfo, 'checked_folders');
  FFilesValidator.ExtractCheckingsInfo(CheckedFoldersArray);

  // Ждём, пока не загрузится превьюшка:
  WaitForSingleObject(DownloadEvent, INFINITE);
  CloseHandle(DownloadEvent);
end;


{
procedure TMinecraftLauncher.LoadInternalPreview;
var
  ResourceStream: TResourceStream;
begin
  try
    ResourceStream := TResourceStream.Create(hInstance, 'DEFAULT_PREVIEW', RT_RCDATA);
    FPreviewBitmap.LoadFromStream(ResourceStream);
    FreeAndNil(ResourceStream);
  except
    FPreviewBitmap.Clear($00000000);
  end;
end;
}



procedure TMinecraftLauncher.SetValidationStatus(Status: Boolean);
begin
  EnterCriticalSection(FValidationStatusCriticalSection);
  FValidationStatus := Status;
  LeaveCriticalSection(FValidationStatusCriticalSection);
end;

function TMinecraftLauncher.GetValidationStatus: Boolean;
begin
  EnterCriticalSection(FValidationStatusCriticalSection);
  Result := FValidationStatus;
  LeaveCriticalSection(FValidationStatusCriticalSection);
end;

function TMinecraftLauncher.InsertParams(const ParametrizedString, BaseFolder: string;
  const UserInfo: TUserInfo; const JavaInfo: TJavaInfo): string;
var
  ClientDir, AssetsDir, JavaRoot, JavaRuntime, NonSpacedClientDir: string;
begin
  ClientDir   := FixSlashes(BaseFolder + '\' + FServerInfo.ClientFolder);
  NonSpacedClientDir := ReplaceParam(ClientDir, ' ', '%20');

  AssetsDir   := FixSlashes(NonSpacedClientDir  + '\' + FServerInfo.AssetsFolder);
  JavaRoot    := FixSlashes(BaseFolder + '\' + JavaInfo.JavaParameters.JavaFolder);
  JavaRuntime := FixSlashes(JavaRoot   + '\' + JavaInfo.JavaParameters.JVMPath);

  Result := ParametrizedString;

  Result := ReplaceParam(Result, '$username'      , UserInfo.UserLogonData.Login);
  Result := ReplaceParam(Result, '$ns_client_dir' , NonSpacedClientDir);
  Result := ReplaceParam(Result, '$ns_client_path', NonSpacedClientDir);
  Result := ReplaceParam(Result, '$client_dir'    , ClientDir);
  Result := ReplaceParam(Result, '$client_path'   , ClientDir);
  Result := ReplaceParam(Result, '$client_version', FServerInfo.Version);
  Result := ReplaceParam(Result, '$version'       , FServerInfo.Version);
  Result := ReplaceParam(Result, '$access_token'  , UserInfo.UserLogonData.AccessToken);
  Result := ReplaceParam(Result, '$uuid'          , UserInfo.UserLogonData.UUID);
  Result := ReplaceParam(Result, '$ip'            , FServerInfo.IP);
  Result := ReplaceParam(Result, '$port'          , FServerInfo.Port);

  Result := ReplaceParam(Result, '$java_root'     , JavaRoot);
  Result := ReplaceParam(Result, '$java_runtime'  , JavaRuntime);

  Result := ReplaceParam(Result, '${auth_player_name}' , UserInfo.UserLogonData.Login);
  Result := ReplaceParam(Result, '${version_name}'     , FServerInfo.Version);
  Result := ReplaceParam(Result, '${game_directory}'   , NonSpacedClientDir);
  Result := ReplaceParam(Result, '${assets_root}'      , AssetsDir);
  Result := ReplaceParam(Result, '${game_assets}'      , AssetsDir);
  Result := ReplaceParam(Result, '${assets_index_name}', FServerInfo.AssetIndex);
  Result := ReplaceParam(Result, '${auth_access_token}', UserInfo.UserLogonData.AccessToken);
  Result := ReplaceParam(Result, '${auth_session}'     , UserInfo.UserLogonData.AccessToken);
  Result := ReplaceParam(Result, '${auth_uuid}'        , UserInfo.UserLogonData.UUID);
  Result := ReplaceParam(Result, '${user_type}'        , 'legacy');
  Result := ReplaceParam(Result, '${user_properties}'  , '[]');
end;



procedure TMinecraftLauncher.FillParams(const BaseFolder: string;
  const UserInfo: TUserInfo; const JavaInfo: TJavaInfo);
var
  JarFoldersCount: Integer;
begin
  JarFoldersCount := Length(FServerInfo.JarFolders);
  if JarFoldersCount > 0 then TParallel.&For(0, JarFoldersCount - 1, procedure(I: Integer)
  begin
    FServerInfo.JarFolders[I] := InsertParams(FServerInfo.JarFolders[I], BaseFolder, UserInfo, JavaInfo);
  end);

  FServerInfo.Arguments     := InsertParams(FServerInfo.Arguments    , BaseFolder, UserInfo, JavaInfo);
  FServerInfo.NativesFolder := InsertParams(FServerInfo.NativesFolder, BaseFolder, UserInfo, JavaInfo);
end;

function TMinecraftLauncher.Launch(const BaseFolder: string;
  const UserInfo: TUserInfo; const JavaInfo: TJavaInfo; RAM: Integer; OptimizeJVM: Boolean; ExperimentalOptimization: Boolean): JNI_RETURN_VALUES;
var
  WorkingFolder, NativesPath, ClassPath, JVMPath: string;
  JarsList, ScanningFolder: string;
  I, JarFoldersCount: Integer;
  JVMParams, Arguments: TStringList;
{$IFDEF DEBUG}
  DebugLog: TStringList;
{$ENDIF}
begin
  WorkingFolder := FixSlashes(BaseFolder + '\' + FServerInfo.ClientFolder);

  // Подставляем аргументы в параметризованные данные:
  FillParams(BaseFolder, UserInfo, JavaInfo);

  // Получаем путь к джаве:
  if JavaInfo.ExternalJava then
    JVMPath := JavaInfo.JavaParameters.JVMPath
  else
    JVMPath := BaseFolder + '\' + JavaInfo.JavaParameters.JavaFolder + '\' + JavaInfo.JavaParameters.JVMPath;

  // Получаем список файлов в соответствии со списком jars:
  JarsList := '';
  JarFoldersCount := Length(FServerInfo.JarFolders);
  if JarFoldersCount = 0 then Exit(JNIWRAPPER_INVALID_ARGUMENTS);
  for I := 0 to JarFoldersCount - 1 do
  begin
  {
    // Если в jars указываем папки ("name" : "folder"):
    ScanningFolder := FixSlashes(WorkingFolder + '\' + FServerInfo.JarFolders[I]);
    GetFilesList(ScanningFolder, '*.jar', ';', JarsList);
    GetFilesList(ScanningFolder, '*.zip', ';', JarsList);
  }
    // Если в jars указываем маски\имена ("name" : "folder/*.jar"):
    ScanningFolder := FixSlashes(WorkingFolder + '\' + FileAPI.ExtractFileDir(FServerInfo.JarFolders[I]));
    GetFilesList(ScanningFolder, FileAPI.ExtractFileName(FServerInfo.JarFolders[I]), ';', JarsList);
  end;

  // Формируем строки с аргументами:
  ClassPath   := '-Djava.class.path=' + JarsList;
  NativesPath := '-Djava.library.path=' + WorkingFolder + '\' + FServerInfo.NativesFolder;

  // Собираем весь список JVM-аргументов:
  JVMParams := TStringList.Create;
  JVMParams.Clear;
  JVMParams.Text := ReplaceParam(JavaInfo.JavaParameters.Arguments, ' ', #13#10);
  //JVMParams.Add('-Xms96m');
  JVMParams.Add('-Xms256m');
  JVMParams.Add('-Xmn128m');
  JVMParams.Add('-Xmx' + IntToStr(RAM) + 'm');

  // Флаги, которые использует TLauncher для запуска Майнкрафта.
  //JVMParams.Add('-XX:HeapDumpPath=ThisTricksIntelDriversForPerformance_javaw.exe_minecraft.exe.heapdump');
  //JVMParams.Add('-XX:+UseConcMarkSweepGC');
  //JVMParams.Add('-XX:-UseAdaptiveSizePolicy');
  //JVMParams.Add('-XX:-UseGCOverheadLimit');
  //JVMParams.Add('-XX:+CMSParallelRemarkEnabled');
  //JVMParams.Add('-XX:+ParallelRefProcEnabled');
  //JVMParams.Add('-XX:+CMSClassUnloadingEnabled');
  //JVMParams.Add('-XX:+UseCMSInitiatingOccupancyOnly');

  JVMParams.Add(NativesPath);
  JVMParams.Add(ClassPath);
  JVMParams.Add('-Dfml.ignoreInvalidMinecraftCertificates=true');
  JVMParams.Add('-Dfml.ignorePatchDiscrepancies=true');

  if OptimizeJVM then
  begin
    if CPUInfo.CPUFeatures.SSE.SSE41 or CPUInfo.CPUFeatures.SSE.SSE42 then JVMParams.Add('-XX:UseSSE=4')
    else if CPUInfo.CPUFeatures.SSE.SSE3 then JVMParams.Add('-XX:UseSSE=3')
    else if CPUInfo.CPUFeatures.SSE.SSE2 then JVMParams.Add('-XX:UseSSE=2')
    else if CPUInfo.CPUFeatures.SSE.SSE1 then JVMParams.Add('-XX:UseSSE=1');

    if CPUInfo.CPUFeatures.SSE.SSE2 then
    begin
      JVMParams.Add('-XX:+UseXmmI2D');
      JVMParams.Add('-XX:+UseXmmI2F');
      JVMParams.Add('-XX:+UseUnalignedLoadStores');
    end;

    if CPUInfo.CPUFeatures.SSE.SSE42 then JVMParams.Add('-XX:+UseSSE42Intrinsics');
    if CPUInfo.CPUFeatures.AVX       then JVMParams.Add('-XX:UseAVX=2');

    if CPUInfo.CPUFeatures.AES then
    begin
      JVMParams.Add('-XX:+UseAES');
      JVMParams.Add('-XX:+UseAESIntrinsics');
    end;
  end;

  if ExperimentalOptimization then
  begin
    JVMParams.Add('-XX:+UnlockDiagnosticVMOptions');

    JVMParams.Add('-XX:+UseIncDec');
    JVMParams.Add('-XX:+UseNewLongLShift');
    JVMParams.Add('-XX:+UseFastStosb');

    JVMParams.Add('-XX:+DisableAttachMechanism');
  end;

  // Собираем список аргументов клиента:
  Arguments := TStringList.Create;
  Arguments.Clear;
  Arguments.Text := ReplaceParam(FServerInfo.Arguments, ' ', #13#10);
  Arguments.Text := ReplaceParam(Arguments.Text, '%20', ' ');

  {$IFDEF DEBUG}
    DebugLog := TStringList.Create;
    DebugLog.Clear;
    DebugLog.Add('=== Client arguments ===');
    DebugLog.Add(#13#10);
    DebugLog.Add(Arguments.Text);
    DebugLog.Add(#13#10);
    DebugLog.Add('Main class: ' + FServerInfo.MainClass);
    DebugLog.Add(#13#10);
    DebugLog.Add('=== JVM Arguments ===');
    DebugLog.Add(#13#10);
    DebugLog.Add(JVMParams.Text);
    DebugLog.Add(#13#10);
    DebugLog.Add('JVM Path: ' + JVMPath);
    DebugLog.Add('JNI Version: ' + IntToStr(JavaInfo.JavaParameters.JNIVersion));
    DebugLog.SaveToFile('DebugLog.txt');
    FreeAndNil(DebugLog);
  {$ENDIF}

  // Готовим файловую систему:
  SetCurrentDirectory(PChar(WorkingFolder));
  SetDllDirectory(PChar(ExtractFileDir(ExtractFileDir(FixSlashes(JVMPath)))));
  DeleteDirectory(WorkingFolder + '\assets\skins', True);

  // Запускаем игру:
  Result := LaunchJavaApplet(
                              JVMPath,
                              JavaInfo.JavaParameters.JNIVersion,
                              JVMParams,
                              ReplaceParam(FServerInfo.MainClass, '.', '/'),
                              Arguments
                             );
end;

procedure TMinecraftLauncher.Clear;
var
  I: Integer;
begin
  with FServerInfo do
  begin
    Name := '';
    Info := '';
    IP   := '';
    Port := '';
    ClientFolder  := '';
    NativesFolder := '';
    AssetsFolder  := '';
    AssetIndex    := '';
    Version       := '';
    MainClass     := '';
    Arguments     := '';

    for I := 0 to Length(JarFolders) - 1 do JarFolders[I] := '';
    SetLength(JarFolders, 0);
  end;

  FHasPreview := False;
  FMonitoringStatus := False;
  SetValidationStatus(False);
  FPreviewBitmap.Clear($00000000);
  FFilesValidator.Clear;
end;


procedure TMinecraftLauncher.StartMonitoring(ServerNumber, Interval: Integer;
  OnMonitoring: TOnMonitoring);
begin
  StopMonitoring;
  FMonitoringStatus := True;
  TThread.CreateAnonymousThread(procedure()
  var
    MonitoringInfo: TMonitoringInfo;
    AnsiIP: AnsiString;
    wPort: Word;
    InitialTimer, RemainingTime, ElapsedTime: Double;
  begin
    TThread.CurrentThread.FreeOnTerminate := True;

    wPort := StrToInt(ServerInfo.Port);
    AnsiIP := WideToAnsi(ServerInfo.IP);
    while FMonitoringStatus do
    begin
      InitialTimer := GetTimer;
      GetServerInfo(AnsiIP, wPort, MonitoringInfo, Interval);
      ElapsedTime := GetTimer - InitialTimer;
      RemainingTime := (Interval / 1000) - ElapsedTime;

      TThread.Synchronize(TThread.CurrentThread, procedure()
      begin
        if FMonitoringStatus then
          if Assigned(OnMonitoring) then OnMonitoring(ServerNumber, MonitoringInfo);
      end);

      if RemainingTime > 0.001 then
        Sleep(Round(RemainingTime * 1000));
    end;
  end).Start;
end;

procedure TMinecraftLauncher.StopMonitoring;
begin
  FMonitoringStatus := False;
end;


end.
