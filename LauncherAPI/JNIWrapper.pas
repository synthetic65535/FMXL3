unit JNIWrapper;

interface

uses
  Windows, Classes, CodepageAPI;

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
