unit HTTPMultiLoader;

interface

uses
  Windows, SysUtils, Classes, HTTPUtils, StringsAPI, FileAPI, ShellApi,
  Generics.Collections, System.Threading, ArithmeticAverage, TimeManagement, LauncherSettings;

type
  TDownloadError = record
    Link        : string;
    Destination : string;
    Reason      : string;
  end;
  TDownloadErrorsList = TList<TDownloadError>;

  TDownloadFileInfo = record
    Size: Integer;
    RelativeLink: string;
  end;
  TDownloadList = TList<TDownloadFileInfo>;

  TSummaryDownloadInfo = record
    IsFinished      : Boolean; // Завершили ли загрузку
    IsCancelled     : Boolean; // Прекратили ли загрузку вследствие внешней отмены
    IsPaused        : Boolean; // Поставлена ли загрузка на паузу
    IsAllDownloaded : Boolean; // Загрузили ли весь список
    FilesCount      : Integer; // Количество файлов для загрузки
    FilesDownloaded : Integer; // Загружено файлов
    FullSize        : UInt64;  // Полный размер в байтах
    Downloaded      : UInt64;  // Загружено байт
    Speed           : Single;  // Байт в секунду
    RemainingTime   : Single;  // В секундах
  end;
  TOnMultiLoad = reference to procedure(
                                         const SummaryDownloadInfo: TSummaryDownloadInfo;
                                         const CurrentDownloadInfo: TDownloadInfo;
                                         const HTTPSender: THTTPSender
                                        );

  THTTPMultiLoader = class
    private const
      UPDATE_INTERVAL      : Double = 0.6; // Интервал в секундах между пересчётом времени и скорости
      TICK_UPDATE_INTERVAL : Double = 0.3; // Интервал в секундах между обновлением тиковой информации
    private
      // Управление загрузкой:
      FPauseEvent       : THandle;
      FDownloadingEvent : THandle;
      FIsPaused         : Boolean;
      FIsCancelled      : Boolean;
      FIsDownloading    : Boolean;

      FDownloadErrorsList : TDownloadErrorsList; // Список файлов, которые не получилось загрузить

      // Параметры множественной загрузки:
      FAccumulator: UInt64; // Количество байт, загруженных за один период обновления

      // Таймер для пересчёта глобальной информации:
      FInitialTimerValue : Double; // Начальный момент времени
      FCurrentTimerValue : Double; // Момент времени, когда загрузили "единичный" блок данных
      FElapsedTime       : Double; // Время, затраченное на загрузку количества байт в Accumulator'е

      // Таймер для обновления тиковой информации:
      FTickInitialTimerValue : Double; // Начальный момент времени
      FTickCurrentTimerValue : Double; // Момент времени, когда загрузили "единичный" блок данных
      FTickElapsedTime       : Double; // Время, затраченное на загрузку количества байт в Accumulator'е

      FAverageSpeed: TAverageOverLastValues; // Усреднённая скорость загрузки

      // Критическая секция для доступа к FSummaryDownloadInfo в многопоточной загрузке:
      FMultiLoadCriticalSection: _RTL_CRITICAL_SECTION;

      // Настройки загрузки:
      FOnMultiLoad       : TOnMultiLoad;
      FDownloads         : TDownloadList;
      FLocalBaseFolder   : string;
      FRemoteBaseAddress : string;

      // Общий статус загрузки:
      FSummaryDownloadInfo: TSummaryDownloadInfo;

      procedure Clear;
      procedure CalculateFullSizeAndFilesCount;
      procedure CalculateSpeedAndTime;
      procedure UpdateDownloadInfo(const MainThread: TThread; const DownloadInfo: TDownloadInfo; const HTTPSender: THTTPSender);
      procedure SendFinalUpdate(const MainThread: TThread);
      procedure DownloadInSingleThread;
      procedure DownloadInMultiThreads;
    public
      property DownloadingEvent: THandle read FDownloadingEvent;

      property IsDownloading: Boolean read FIsDownloading;
      property IsPaused: Boolean read FIsPaused;
      property IsCancelled: Boolean read FIsCancelled;

      constructor Create;
      destructor Destroy; override;

      function DownloadList(
                             const LocalBaseFolder, RemoteBaseAddress: string;
                             const Downloads: TDownloadList;
                             MultiThreading: Boolean = False;
                             OnMultiLoad: TOnMultiLoad = nil
                            ): Boolean;

      procedure Pause;
      procedure Resume;
      procedure Cancel;
      procedure WaitForDownloadComplete;
  end;

implementation

{ THTTPMultiLoader }


procedure THTTPMultiLoader.Clear;
begin
  FIsCancelled   := False;
  FIsPaused      := False;
  FIsDownloading := False;

  FDownloadErrorsList.Clear;

  FAccumulator       := 0;
  FInitialTimerValue := 0;
  FCurrentTimerValue := 0;
  FElapsedTime       := 0;

  FAverageSpeed.Clear;

  with FSummaryDownloadInfo do
  begin
    IsFinished      := False;
    IsCancelled     := False;
    IsAllDownloaded := False;
    FilesCount      := 0;
    FilesDownloaded := 0;
    FullSize        := 0;
    Downloaded      := 0;
    Speed           := 0;
    RemainingTime   := 0;
  end;

  if Assigned(FDownloads) then FreeAndNil(FDownloads);
  FLocalBaseFolder   := '';
  FRemoteBaseAddress := '';

  SetEvent(FPauseEvent);
  SetEvent(FDownloadingEvent);
end;


constructor THTTPMultiLoader.Create;
begin
  FPauseEvent         := CreateEvent(nil, True, True, nil);
  FDownloadingEvent   := CreateEvent(nil, True, True, nil);
  FDownloadErrorsList := TDownloadErrorsList.Create;
  FAverageSpeed       := TAverageOverLastValues.Create(5);
  FDownloads          := nil;

  InitializeCriticalSection(FMultiLoadCriticalSection);

  Clear;
end;


destructor THTTPMultiLoader.Destroy;
begin
  // Отменяем загрузку и ждём, пока все потоки отработают:
  if FIsDownloading then
  begin
    Cancel;
    WaitForDownloadComplete;
  end;

  // Закрываем хэндлы:
  CloseHandle(FPauseEvent);
  CloseHandle(FDownloadingEvent);
  DeleteCriticalSection(FMultiLoadCriticalSection);

  // Чистим память и удаляем объекты:
  Clear;
  FreeAndNil(FDownloadErrorsList);
  FreeAndNil(FAverageSpeed);

  inherited;
end;


procedure THTTPMultiLoader.CalculateFullSizeAndFilesCount;
var
  I: Integer;
begin
  FSummaryDownloadInfo.FilesCount := FDownloads.Count;
  for I := 0 to FDownloads.Count - 1 do
  begin
    Inc(FSummaryDownloadInfo.FullSize, FDownloads[I].Size);
  end;
end;


procedure THTTPMultiLoader.CalculateSpeedAndTime;
var
  CurrentSpeed: Single;
begin
  CurrentSpeed := FAccumulator / FElapsedTime;
  with FSummaryDownloadInfo do
  begin
    Speed := FAverageSpeed.Add(CurrentSpeed);

    if Downloaded > FullSize then Downloaded := FullSize;

    RemainingTime := (FullSize - Downloaded) / FAverageSpeed.LastAverage;
  end;
end;


procedure THTTPMultiLoader.UpdateDownloadInfo(const MainThread: TThread; const DownloadInfo: TDownloadInfo; const HTTPSender: THTTPSender);
var
  CurrentDownloadInfo: TDownloadInfo;
begin
  FCurrentTimerValue := GetTimer;
  FTickCurrentTimerValue := FCurrentTimerValue;

  FElapsedTime := FCurrentTimerValue - FInitialTimerValue;
  FTickElapsedTime := FTickCurrentTimerValue - FTickInitialTimerValue;

  if (FElapsedTime >= UPDATE_INTERVAL) then
  begin
    if not DownloadInfo.IsDownloaded then
    begin
      CalculateSpeedAndTime;
      FAccumulator := 0;
    end;

    FInitialTimerValue := GetTimer;
  end;

  if (FTickElapsedTime >= TICK_UPDATE_INTERVAL) then
  begin
    CurrentDownloadInfo := DownloadInfo;
    TThread.Synchronize(MainThread, procedure()
    begin
      FOnMultiLoad(FSummaryDownloadInfo, CurrentDownloadInfo, HTTPSender);
    end);
    FTickInitialTimerValue := GetTimer;
  end;
end;

procedure THTTPMultiLoader.SendFinalUpdate(const MainThread: TThread);
begin
  CalculateSpeedAndTime;

  FSummaryDownloadInfo.IsAllDownloaded := FSummaryDownloadInfo.FilesCount = FSummaryDownloadInfo.FilesDownloaded;
  FSummaryDownloadInfo.IsFinished := True;

  SetEvent(FDownloadingEvent);

  TThread.Synchronize(MainThread, procedure()
  var
    FinalDownloadStatus: TDownloadInfo;
  begin
    FIsDownloading := False;

    FillChar(FinalDownloadStatus, SizeOf(FinalDownloadStatus), #0);
    if Assigned(FOnMultiLoad) then
      FOnMultiLoad(FSummaryDownloadInfo, FinalDownloadStatus, nil);
  end);
end;


procedure THTTPMultiLoader.DownloadInSingleThread;
var
  I: Integer;
  MainThread: TThread;
  Link, Destination: string;
  HTTPSender: THTTPSender;
  DownloadError: TDownloadError;
begin
  ResetEvent(FDownloadingEvent);

  MainThread := TThread.Current;
  MainThread.FreeOnTerminate := True;

  CalculateFullSizeAndFilesCount;

  // Засекаем начальное время:
  FInitialTimerValue     := GetTimer;
  FTickInitialTimerValue := FInitialTimerValue;

  HTTPSender := THTTPSender.Create;
  if FDownloads.Count > 0 then for I := 0 to FDownloads.Count - 1 do
  begin
    if FIsCancelled then Break;

    Link        := FixSlashes(FRemoteBaseAddress + '/' + FDownloads[I].RelativeLink, True);
    Destination := FixSlashes(FLocalBaseFolder + '\' + FDownloads[I].RelativeLink);

    if FileExists(Destination + '_copy.exe') then
    begin
      ShellExecute(0, nil, pchar(Destination + '_copy.exe'), pchar('-p' + SFXPassword), pchar(ExtractFilePath(Destination)), SW_NORMAL);
    end else
      begin

      HTTPSender.Clear;
      HTTPSender.DownloadFile(Link, procedure(const DownloadInfo: TDownloadInfo)
      begin
        WaitForSingleObject(FPauseEvent, INFINITE);
        if FIsCancelled then
        begin
          HTTPSender.HTTPSend.Sock.SetRecvTimeout(10);
          HTTPSender.HTTPSend.Sock.CloseSocket;
          Exit;
        end;

        Inc(FAccumulator, DownloadInfo.TickDownloaded);
        Inc(FSummaryDownloadInfo.Downloaded, DownloadInfo.TickDownloaded);
        UpdateDownloadInfo(MainThread, DownloadInfo, HTTPSender);
      end);

      if FIsCancelled then Break;

      // Если не получилось скачать - добавляем в список ошибочных файлов:
      if not HTTPSender.IsSuccessfulStatus then
      begin
        DownloadError.Link        := Link;
        DownloadError.Destination := Destination;
        DownloadError.Reason      := IntToStr(HTTPSender.StatusCode) + ' ' + HTTPSender.StatusString;
        FDownloadErrorsList.Add(DownloadError);
      end;

      CreatePath(ExtractFilePath(Destination));
      HTTPSender.HTTPSend.Document.SaveToFile(Destination);

      end;

    Inc(FSummaryDownloadInfo.FilesDownloaded);
  end;

  FreeAndNil(HTTPSender);

  SendFinalUpdate(MainThread);
end;


procedure THTTPMultiLoader.DownloadInMultiThreads;
var
  MainThread: TThread;
begin
  ResetEvent(FDownloadingEvent);

  MainThread := TThread.Current;
  MainThread.FreeOnTerminate := True;

  CalculateFullSizeAndFilesCount;

  // Засекаем начальное время:
  FInitialTimerValue     := GetTimer;
  FTickInitialTimerValue := FInitialTimerValue;

  if FDownloads.Count > 0 then TParallel.&For(0, FDownloads.Count - 1, procedure(I: Integer; LoopState: TParallel.TLoopState)
  var
    Link, Destination: string;
    HTTPSender: THTTPSender;
    DownloadError: TDownloadError;
  begin
    if FIsCancelled then
    begin
      LoopState.Break;
      Exit;
    end;

    Link        := FixSlashes(FRemoteBaseAddress + '/' + FDownloads[I].RelativeLink, True);
    Destination := FixSlashes(FLocalBaseFolder + '\' + FDownloads[I].RelativeLink);

    if FileExists(Destination + '_copy.exe') then
    begin
      ShellExecute(0, nil, pchar(Destination + '_copy.exe'), pchar('-p' + SFXPassword), pchar(ExtractFilePath(Destination)), SW_NORMAL);
    end else
      begin

      // Запускаем загрузку:
      HTTPSender := THTTPSender.Create;
      HTTPSender.DownloadFile(Link, procedure(const DownloadInfo: TDownloadInfo)
      begin
        WaitForSingleObject(FPauseEvent, INFINITE);
        if FIsCancelled then
        begin
          HTTPSender.HTTPSend.Sock.SetRecvTimeout(10);
          HTTPSender.HTTPSend.Sock.CloseSocket;
          Exit;
        end;

        EnterCriticalSection(FMultiLoadCriticalSection);
        Inc(FAccumulator, DownloadInfo.TickDownloaded);
        Inc(FSummaryDownloadInfo.Downloaded, DownloadInfo.TickDownloaded);
        UpdateDownloadInfo(MainThread, DownloadInfo, HTTPSender);
        LeaveCriticalSection(FMultiLoadCriticalSection);
      end);

      if FIsCancelled then
      begin
        FreeAndNil(HTTPSender);
        LoopState.Break;
        Exit;
      end;

      // Если не получилось скачать - добавляем в список ошибочных файлов:
      if not HTTPSender.IsSuccessfulStatus then
      begin
        EnterCriticalSection(FMultiLoadCriticalSection);
        DownloadError.Link        := Link;
        DownloadError.Destination := Destination;
        DownloadError.Reason      := IntToStr(HTTPSender.StatusCode) + ' ' + HTTPSender.StatusString;
        FDownloadErrorsList.Add(DownloadError);
        LeaveCriticalSection(FMultiLoadCriticalSection);
      end;

      CreatePath(ExtractFilePath(Destination));
      HTTPSender.HTTPSend.Document.SaveToFile(Destination);

      end;

    FreeAndNil(HTTPSender);

    EnterCriticalSection(FMultiLoadCriticalSection);
    Inc(FSummaryDownloadInfo.FilesDownloaded);
    LeaveCriticalSection(FMultiLoadCriticalSection);
  end);

  SendFinalUpdate(MainThread);
end;


function THTTPMultiLoader.DownloadList(const LocalBaseFolder, RemoteBaseAddress: string;
  const Downloads: TDownloadList; MultiThreading: Boolean = False; OnMultiLoad: TOnMultiLoad = nil): Boolean;
begin
  if FIsDownloading then Exit(False);

  Clear;

  // Копируем настройки:
  FLocalBaseFolder   := LocalBaseFolder;
  FRemoteBaseAddress := RemoteBaseAddress;
  FDownloads         := TDownloadList.Create(Downloads);
  FOnMultiLoad       := OnMultiLoad;

  // Запускаем поток загрузки:
  FIsDownloading := True;
  if MultiThreading then
    TThread.CreateAnonymousThread(DownloadInMultiThreads).Start
  else
    TThread.CreateAnonymousThread(DownloadInSingleThread).Start;

  Result := True;
end;


procedure THTTPMultiLoader.Pause;
begin
  FIsPaused := True;
  FSummaryDownloadInfo.IsPaused := FIsPaused;
  ResetEvent(FPauseEvent);
end;


procedure THTTPMultiLoader.Resume;
begin
  FIsPaused := False;
  FSummaryDownloadInfo.IsPaused := FIsPaused;
  SetEvent(FPauseEvent);
end;


procedure THTTPMultiLoader.Cancel;
begin
  FIsCancelled := True;
  FSummaryDownloadInfo.IsCancelled := True;
  Resume;
end;

procedure THTTPMultiLoader.WaitForDownloadComplete;
begin
  WaitForSingleObject(FDownloadingEvent, INFINITE);
end;

end.
