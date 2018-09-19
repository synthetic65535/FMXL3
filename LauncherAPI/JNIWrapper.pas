unit JNIWrapper;

interface

uses
  Windows, Classes, CodepageAPI, AuxUtils;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

const
  JNI_VERSION_1_6 = $00010006; // Java 6, Java 7
  JNI_VERSION_1_8 = $00010008; // Java 8
  JNI_VERSION_1_9 = $00010009; // Java 9 // На будущее

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

type
  JNI_RETURN_VALUES = (
    JNIWRAPPER_SUCCESS,
    JNIWRAPPER_UNKNOWN_ERROR,
    JNIWRAPPER_JNI_INVALID_VERSION,
    JNIWRAPPER_NOT_ENOUGH_MEMORY,
    JNIWRAPPER_JVM_ALREADY_EXISTS,
    JNIWRAPPER_INVALID_ARGUMENTS,
    JNIWRAPPER_CLASS_NOT_FOUND,
    JNIWRAPPER_METHOD_NOT_FOUND
  );

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function LaunchJavaApplet(
                           JVMPath: string;               // Путь к jvm.dll
                           JNIVersion: Integer;           // Версия JNI
                           const JVMOptions: TStringList; // Параметры JVM (память, флаги JVM, ClassPath, LibraryPath)
                           MainClass: string;             // Главный класс
                           const Arguments: TStringList   // Аргументы клиента (логин, сессия, ...)
                          ): JNI_RETURN_VALUES;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

implementation

uses
  JNI{, HookAPI, ShlwAPI};

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

type
  TAnsiStorage = record
    Size: LongWord;
    Strings: array of AnsiString;
    Pointers: array of PAnsiChar;
  end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  TWideStorage = record
    Size: LongWord;
    Strings: array of WideString;
    Pointers: array of PWideChar;
  end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  TLibraryStruct = packed record
    JVMPath: PWideChar;
    JNIVersion: Integer;
    JVMOptions: TStringList;
    MainClass: PAnsiChar;
    Arguments: TStringList;
    Response: ^JNI_RETURN_VALUES;

    Semaphore: THandle;
  end;
  PLibraryStruct = ^TLibraryStruct;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

{
procedure SetWorkingDir(JNIEnv: PJNIEnv; Dir: string);
const
  ClassName: PAnsiChar = 'net/minecraft/client/Minecraft';
  FieldName: PAnsiChar = 'java/io/File';
  Signature: PAnsiChar = '()';
var
  MainClass: JClass;
  Field: JFieldID;
begin
  MainClass := JNIEnv^.FindClass(JNIEnv, ClassName);
  Field := JNIEnv^.GetStaticFieldID(JNIEnv, MainClass, FieldName,
end;
}

{
type
  TRegisterNatives = function(Env: PJNIEnv; AClass: JClass; const Methods: PJNINativeMethod; NMethods: JInt): JInt; stdcall;

var
  RegisterNativesHookInfo: THookInfo;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function SetExitHook(JNIEnv: PJNIEnv): Boolean;
  procedure ExitHook(JNIEnv: PJNIEnv; Code: JInt); stdcall;
  begin
    MessageBox(0, 'JVM завершила работу!', 'Внимание!', MB_ICONINFORMATION);
    Exit;
  end;
const
  ClassName: PAnsiChar = 'java/lang/Shutdown';
var
  Method: JNINativeMethod;
  ShutdownClass: JClass;
  RegisterStatus: JInt;
begin
  Method.name      := 'halt0';
  Method.signature := '(I)V';
  Method.fnPtr     := @ExitHook;

  ShutdownClass := JNIEnv^.FindClass(JNIEnv, ClassName);
  if ShutdownClass = nil then Exit(False);

  RegisterStatus := JNIEnv^.RegisterNatives(JNIEnv, ShutdownClass, @Method, 1);
  Result := RegisterStatus >= 0;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{
function HookedRegisterNatives(Env: PJNIEnv; AClass: JClass; const Methods: PJNINativeMethod; NMethods: JInt): JInt; stdcall;
var
  WideMethodName: string;
begin
  WideMethodName := AnsiToWide(PAnsiChar(Methods.name));

  if (WideMethodName = 'halt0') or (WideMethodName = 'attach') or PathMatchSpec(PChar(WideMethodName), 'nal*') then
    Result := TRegisterNatives(RegisterNativesHookInfo.OriginalBlock)(Env, AClass, Methods, NMethods)
  else
    Result := 0;
end;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

type
 PUNICODE_STRING = ^UNICODE_STRING;

 UNICODE_STRING = record
   Length: USHORT;
   MaximumLength: USHORT;
   Buffer: PWideChar;
 end;

 CLIENT_ID = record
   UniqueProcess: THandle;
   UniqueThread: THandle;
 end;

 PCLIENT_ID = ^CLIENT_ID;

 KPRIORITY = Integer;

 _KWAIT_REASON = (
   Executive,
   FreePage,
   PageIn,
   PoolAllocation,
   DelayExecution,
   Suspended,
   UserRequest,
   WrExecutive,
   WrFreePage,
   WrPageIn,
   WrPoolAllocation,
   WrDelayExecution,
   WrSuspended,
   WrUserRequest,
   WrEventPair,
   WrQueue,
   WrLpcReceive,
   WrLpcReply,
   WrVirtualMemory,
   WrPageOut,
   WrRendezvous,
   WrKeyedEvent,
   WrTerminated,
   WrProcessInSwap,
   WrCpuRateControl,
   WrCalloutStack,
   WrKernel,
   WrResource,
   WrPushLock,
   WrMutex,
   WrQuantumEnd,
   WrDispatchInt,
   WrPreempted,
   WrYieldExecution,
   WrFastMutex,
   WrGuardedMutex,
   WrRundown,
   MaximumWaitReason);
 KWAIT_REASON = _KWAIT_REASON;

 SYSTEM_THREADS = record
   KernelTime: FILETIME;
   UserTime: FILETIME;
   CreateTime: FILETIME;
   WaitTime: ULONG;
   StartAddress: PVOID;
   ClientId: CLIENT_ID;
   Priority: KPRIORITY;
   BasePriority: KPRIORITY;
   ContextSwitches: ULONG;
   ThreadState: ULONG;
   WaitReason: KWAIT_REASON;
   Reserved : ULONG;
 end;

 SYSTEM_PROCESS_INFORMATION = record
   NextEntryOffset: ULONG;
   NumberOfThreads: ULONG;
   WorkingSetPrivateSize: Int64;
   HardFaultCount: ULONG;
   NumberOfThreadsHighWatermark: ULONG;
   CycleTime: ULONGLONG;
   CreateTime: FILETIME;
   UserTime: FILETIME;
   KernelTime: FILETIME;
   ImageName: UNICODE_STRING;
   BasePriority: KPRIORITY;
   UniqueProcessId: THandle;
   InheritedFromUniqueProcessId: THandle;
   HandleCount: ULONG;
   SessionId: ULONG;
   UniqueProcessKey: ULONG_PTR;
   PeakVirtualSize: SIZE_T;
   VirtualSize: SIZE_T;
   PageFaultCount: ULONG;
   PeakWorkingSetSize: SIZE_T;
   WorkingSetSize: SIZE_T;
   QuotaPeakPagedPoolUsage: SIZE_T;
   QuotaPagedPoolUsage: SIZE_T;
   QuotaPeakNonPagedPoolUsage: SIZE_T;
   QuotaNonPagedPoolUsage: SIZE_T;
   PagefileUsage: SIZE_T;
   PeakPagefileUsage: SIZE_T;
   PrivatePageCountp: SIZE_T;
   ReadOperationCount: Int64;
   WriteOperationCount: Int64;
   OtherOperationCount: Int64;
   ReadTransferCount: Int64;
   WriteTransferCount: Int64;
   OtherTransferCount: Int64;
   Threads: array [0 .. 0] of SYSTEM_THREADS;
 end;

 PSYSTEM_PROCESS_INFORMATION = ^SYSTEM_PROCESS_INFORMATION;

type
 NTSTATUS = System.LongInt;

const
 STATUS_SUCCESS = NTSTATUS($00000000);
 STATUS_INFO_LENGTH_MISMATCH = NTSTATUS($C0000004);
 SystemProcessesAndThreadsInformation = 5;
 THREAD_STATE_WAITING = 5;

function NtQuerySystemInformation(SystemInformationClass: ULONG; SystemInformation: PVOID; SystemInformationLength: ULONG; ReturnLength: PULONG): NTSTATUS; stdcall; external 'ntdll.dll';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure JVMThread(LibraryStruct: PLibraryStruct); stdcall;
var
  LocalLibraryStruct: TLibraryStruct;

  JVMOptionsStorage : TAnsiStorage;
  ArgumentsStorage  : TWideStorage;

  I: LongWord;
  JNIResult: JInt;

  JVM     : TJavaVM;
  Args    : JavaVMInitArgs;
  Options : array of JavaVMOption;

  LaunchClass : JClass;
  MethodID    : JMethodID;

  JavaObjectArray: JObjectArray;

  JVMThreadID: DWORD;
  ProcessID: Cardinal;
begin
  LocalLibraryStruct := LibraryStruct^;

  with LocalLibraryStruct do
  begin
    // Создаём хранилища строковых данных:
    JVMOptionsStorage.Size := JVMOptions.Count;
    SetLength(JVMOptionsStorage.Strings, JVMOptionsStorage.Size);
    SetLength(JVMOptionsStorage.Pointers, JVMOptionsStorage.Size);

    ArgumentsStorage.Size := Arguments.Count;
    SetLength(ArgumentsStorage.Strings, ArgumentsStorage.Size);
    SetLength(ArgumentsStorage.Pointers, ArgumentsStorage.Size);

    // Параметры JVM - в ANSI-хранилище:
    if JVMOptions.Count > 0 then
      for I := 0 to JVMOptions.Count - 1 do
      begin
        JVMOptionsStorage.Strings[I] := WideToAnsi(JVMOptions[I]);
        JVMOptionsStorage.Pointers[I] := PAnsiChar(JVMOptionsStorage.Strings[I]);
      end;

    // Аргументы клиента - в Unicode-хранилище:
    if Arguments.Count > 0 then
      for I := 0 to Arguments.Count - 1 do
      begin
        ArgumentsStorage.Strings[I] := Arguments[I];
        ArgumentsStorage.Pointers[I] := PWideChar(ArgumentsStorage.Strings[I]);
      end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    // Загружаем JVM:
    JVM := TJavaVM.Create(JNIVersion, JVMPath);

    // Формируем опции: путь к *.jar, *.dll, аргументы JVM:
    SetLength(Options, JVMOptions.Count);
    for I := 0 to JVMOptions.Count - 1 do
      Options[I].optionString := JVMOptionsStorage.Pointers[I];

    // Заполняем структуру аргументов:
    Args.version  := JNIVersion;
    Args.nOptions := JVMOptions.Count;
    Args.options  := @Options[0];
    Args.ignoreUnrecognized := 0;

    // Запускаем JVM:
    JNIResult := JVM.LoadVM(Args);
    if JNIResult <> JNI_OK then
    begin
      case JNIResult of
        JNI_ERR      : Response^ := JNIWRAPPER_UNKNOWN_ERROR;
        JNI_EVERSION : Response^ := JNIWRAPPER_JNI_INVALID_VERSION;
        JNI_ENOMEM   : Response^ := JNIWRAPPER_NOT_ENOUGH_MEMORY;
        JNI_EEXIST   : Response^ := JNIWRAPPER_JVM_ALREADY_EXISTS;
        JNI_EINVAL   : Response^ := JNIWRAPPER_INVALID_ARGUMENTS;
      end;
      JVM.Destroy;
      ReleaseSemaphore(LibraryStruct.Semaphore, 1, nil);
      Exit;
    end;
{
    // Регистрируем фильтр:
    RegisterNativesHookInfo.OriginalProcAddress := @JVM.Env^.RegisterNatives;
    RegisterNativesHookInfo.HookProcAddress := @HookedRegisterNatives;
    SetHook(RegisterNativesHookInfo);
}
    {$IFDEF DEBUG}
      SetExitHook(JVM.Env);
    {$ENDIF}

    // Запускаем поток для слежения за потоком JVM. Исправление вот этого бага:
    // Если прыгнуть в высоты и нажать ПКМ по заголовку окна майнкрафта, то игрок зависнет в воздухе
    // Подробнее: https://www.youtube.com/watch?v=5SeZ--8tRt0
    JVMThreadID := windows.GetCurrentThreadId;
    ProcessID := windows.GetCurrentProcessId;
    TThread.CreateAnonymousThread(procedure()
    var
      SystemInformation: PVOID;
      SystemInformationLength: ULONG;
      ReturnLength: ULONG;
      PSPI: PSYSTEM_PROCESS_INFORMATION;
      Status: NTSTATUS;
      ThreadNumber: Integer;
      ThreadWaitTime: Integer;
    begin
      ThreadWaitTime := 0;
      while true do
        begin
        SystemInformationLength := $400;
        GetMem(SystemInformation, SystemInformationLength);
        Status := NtQuerySystemInformation(SystemProcessesAndThreadsInformation, SystemInformation, SystemInformationLength, @ReturnLength);
        if (Status = STATUS_INFO_LENGTH_MISMATCH) then
        begin
          while (Status = STATUS_INFO_LENGTH_MISMATCH) do
          begin
            FreeMem(SystemInformation);
            SystemInformationLength := SystemInformationLength * 2;
            GetMem(SystemInformation, SystemInformationLength);
            Status := NtQuerySystemInformation(SystemProcessesAndThreadsInformation, SystemInformation, SystemInformationLength, @ReturnLength);
          end;
        end;
        try
         if Status = STATUS_SUCCESS then
          begin
            sleep(100);
            PSPI := PSYSTEM_PROCESS_INFORMATION(SystemInformation);
            repeat
                if (ProcessID = PSPI^.UniqueProcessId) then // Нашли нужный процесс
                begin
                  for ThreadNumber := 0 to PSPI^.NumberOfThreads - 1 do
                  begin
                    if (PSPI^.Threads[ThreadNumber].ClientId.UniqueThread = JVMThreadID) then // Нашли нужный поток
                    begin
                      if (PSPI^.Threads[ThreadNumber].ThreadState = THREAD_STATE_WAITING) then
                      begin
                        if (ThreadWaitTime < 10) then
                          Inc(ThreadWaitTime);
                      end else begin
                        if (ThreadWaitTime > 0) then
                          Dec(ThreadWaitTime);
                      end;
                    end;
                  end;
                end;
              if PSPI^.NextEntryOffset = 0 then
                Break;
              PSPI := PSYSTEM_PROCESS_INFORMATION(DWORD(PSPI) + PSPI^.NextEntryOffset);
            until
              False;
          end;
        finally
          if SystemInformation <> nil then
            FreeMem(SystemInformation);
          SystemInformation := nil;
        end;

        if (ThreadWaitTime >= 10) then // 5 секунд
        begin
          MessageBoxTimeout(0,
                           PChar(
                                  'Основной поток Майнкрафта завис.' + #13#10 +
                                  'Требуется перезапуск лаунчера.'
                                 ),
                           'Minecraft завис!',
                           MB_ICONERROR,
                           0,
                           5000
                          );
          ExitProcess(0);
        end;

        sleep(500);
        end;
    end).Start;

    // Ищем нужный класс:
    LaunchClass := JVM.Env^.FindClass(JVM.Env, PAnsiChar(MainClass));
    if LaunchClass = nil then
    begin
      JVM.DestroyJavaVM;
      JVM.Destroy;
      Response^ := JNIWRAPPER_CLASS_NOT_FOUND;
      ReleaseSemaphore(LibraryStruct.Semaphore, 1, nil);
      Exit;
    end;

    // В нужном классе - нужный метод:
    MethodID := JVM.Env^.GetStaticMethodID(JVM.Env, LaunchClass, 'main', '([Ljava/lang/String;)V');
    if LaunchClass = nil then
    begin
      JVM.DestroyJavaVM;
      JVM.Destroy;
      Response^ := JNIWRAPPER_METHOD_NOT_FOUND;
      ReleaseSemaphore(LibraryStruct.Semaphore, 1, nil);
      Exit;
    end;

    // Создаём массив для аргументов:
    JavaObjectArray := JVM.Env^.NewObjectArray(JVM.Env, Arguments.Count, JVM.Env^.FindClass(JVM.Env, 'java/lang/String'), JVM.Env^.NewString(JVM.Env, nil, 0));

    // Заполняем аргументы (логин, сессия и т.д.):
    if Arguments.Count > 0 then
      for I := 0 to Arguments.Count - 1 do
        JVM.Env^.SetObjectArrayElement(JVM.Env, JavaObjectArray, I, JVM.Env^.NewString(JVM.Env, PJChar(ArgumentsStorage.Pointers[I]), Length(ArgumentsStorage.Strings[I])));

    Response^ := JNIWRAPPER_SUCCESS;
    ReleaseSemaphore(LibraryStruct.Semaphore, 1, nil);

    // Вызываем метод:
    JVM.Env^.CallStaticVoidMethodA(JVM.Env, LaunchClass, MethodID, @JavaObjectArray);

    JVM.DestroyJavaVM;
    JVM.Destroy;
  end;
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


function LaunchJavaApplet(
                           JVMPath: string;
                           JNIVersion: Integer;
                           const JVMOptions: TStringList;
                           MainClass: string;
                           const Arguments: TStringList
                          ): JNI_RETURN_VALUES;

var
  LibraryStruct: TLibraryStruct;
begin
  FillChar(LibraryStruct, SizeOf(LibraryStruct), #0);

  LibraryStruct.JVMPath    := PWideChar(JVMPath);
  LibraryStruct.JNIVersion := JNIVersion;
  LibraryStruct.JVMOptions := JVMOptions;
  LibraryStruct.MainClass  := PAnsiChar(WideToAnsi(MainClass));
  LibraryStruct.Arguments  := Arguments;
  LibraryStruct.Response   := @Result;

  LibraryStruct.Semaphore := CreateSemaphore(nil, 0, 1, nil);
  CloseHandle(CreateThread(nil, 0, @JVMThread, @LibraryStruct, 0, PCardinal(0)^));

  WaitForSingleObject(LibraryStruct.Semaphore, INFINITE);
  CloseHandle(LibraryStruct.Semaphore);
end;

end.
