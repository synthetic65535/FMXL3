program FMXL3;

{$I Definitions.inc}

uses
  System.StartUpCopy,
  Windows,
  Math,
  Classes,
  FMX.Forms,
  Main in 'Main.pas' {MainForm},
  cHash in 'cHash\cHash.pas',
  ArithmeticAverage in 'HoShiMin''s API\ArithmeticAverage.pas',
  CodepageAPI in 'HoShiMin''s API\CodepageAPI.pas',
  FileAPI in 'HoShiMin''s API\FileAPI.pas',
  JSONUtils in 'HoShiMin''s API\JSONUtils.pas',
  StringsAPI in 'HoShiMin''s API\StringsAPI.pas',
  TimeManagement in 'HoShiMin''s API\TimeManagement.pas',
  Authorization in 'LauncherAPI\Authorization.pas',
  AuxUtils in 'LauncherAPI\AuxUtils.pas',
  DownloadHelper in 'LauncherAPI\DownloadHelper.pas',
  Encryption in 'LauncherAPI\Encryption.pas',
  HTTPMultiLoader in 'LauncherAPI\HTTPMultiLoader.pas',
  HTTPUtils in 'LauncherAPI\HTTPUtils.pas',
  HWID in 'LauncherAPI\HWID.pas',
  JavaInformation in 'LauncherAPI\JavaInformation.pas',
  JNIWrapper in 'LauncherAPI\JNIWrapper.pas',
  LauncherAPI in 'LauncherAPI\LauncherAPI.pas',
  LauncherInformation in 'LauncherAPI\LauncherInformation.pas',
  MinecraftLauncher in 'LauncherAPI\MinecraftLauncher.pas',
  MultipartPostRequest in 'LauncherAPI\MultipartPostRequest.pas',
  Registration in 'LauncherAPI\Registration.pas',
  ServerQuery in 'LauncherAPI\ServerQuery.pas',
  ServersInformation in 'LauncherAPI\ServersInformation.pas',
  SkinSystem in 'LauncherAPI\SkinSystem.pas',
  UserInformation in 'LauncherAPI\UserInformation.pas',
  FilesScanner in 'LauncherAPI\FilesValidation\FilesScanner.pas',
  FilesValidation in 'LauncherAPI\FilesValidation\FilesValidation.pas',
  ValidationTypes in 'LauncherAPI\FilesValidation\ValidationTypes.pas',
  JNI in 'LauncherAPI\JNI\JNI.pas',
  JNIUtils in 'LauncherAPI\JNI\JNIUtils.pas',
  blcksock in 'Synapse\blcksock.pas',
  httpsend in 'Synapse\httpsend.pas',
  synacode in 'Synapse\synacode.pas',
  synafpc in 'Synapse\synafpc.pas',
  synaip in 'Synapse\synaip.pas',
  synautil in 'Synapse\synautil.pas',
  synsock in 'Synapse\synsock.pas',
  LauncherSettings in 'LauncherSettings.pas',
  RegistryUtils in 'HoShiMin''s API\RegistryUtils.pas',
  FormatPE in 'HoShiMin''s API\FormatPE.pas',
  PowerUP in 'HoShiMin''s API\PowerUP.pas',
  PopupManager in 'AuxUtils\PopupManager.pas',
  ServerPanel in 'AuxUtils\ServerPanel.pas',
  StackCapacitor in 'AuxUtils\StackCapacitor.pas',
  FilesNotifier in 'HoShiMin''s API\FilesNotifier.pas',
  CPUIDInfo in 'HoShiMin''s API\CPUIDInfo.pas',
  ssl_openssl in 'Synapse\ssl_openssl.pas',
  ssl_openssl_lib in 'Synapse\ssl_openssl_lib.pas',
  ResUnpacker in 'AuxUtils\ResUnpacker.pas',
{$IFDEF ENABLE_EXECUTABLE_MEMORY_DEFENCE}
  AvnApi in 'Avanguard\AvnApi.pas',
{$ENDIF}
  CPU in 'DEC\CPU.pas',
  CRC in 'DEC\CRC.pas',
  DECCipher in 'DEC\DECCipher.pas',
  DECData in 'DEC\DECData.pas',
  DECFmt in 'DEC\DECFmt.pas',
  DECHash in 'DEC\DECHash.pas',
  DECRandom in 'DEC\DECRandom.pas',
  DECUtil in 'DEC\DECUtil.pas'
;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{$R *.res}
{$R Fonts.res}
{$R DefaultImages.res}

{$IFDEF USE_SSL}
  {$IFDEF CPUX64}
    {$R OpenSSL64.res}
  {$ELSE}
    {$R OpenSSL32.res}
  {$ENDIF}
{$ENDIF}

{$IFDEF ENABLE_EXECUTABLE_MEMORY_DEFENCE}
  {$IFDEF CPUX64}
    {$R Avanguard64.res}
  {$ELSE}
    {$R Avanguard32.res}
  {$ENDIF}
{$ENDIF}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$SETPEFLAGS
  $0001 or (* IMAGE_FILE_RELOCS_STRIPPED         *)
  $0004 or (* IMAGE_FILE_LINE_NUMS_STRIPPED      *)
  $0008 or (* IMAGE_FILE_LOCAL_SYMS_STRIPPED     *)
  $0020 or (* IMAGE_FILE_LARGE_ADDRESS_AWARE     *)
  $0200 or (* IMAGE_FILE_DEBUG_STRIPPED          *)
  $0400 or (* IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP *)
  $0800    (* IMAGE_FILE_NET_RUN_FROM_SWAP       *)
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{$IFDEF DEBUG}
  {$APPTYPE CONSOLE}
{$ELSE}
  {$APPTYPE GUI}
{$ENDIF}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function LoadResourceFont(Instance: THandle; FontName: string; ResType: PChar = RT_RCDATA): THandle;
var
  Res: TResourceStream;
  Count: Integer;
begin
  Res:= TResourceStream.Create(Instance, FontName, ResType);
  try
    Result := AddFontMemResourceEx(Res.Memory, Res.Size, nil, @Count);
  finally
    Res.Free;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure FreeResourceFont(Font: THandle);
begin
  RemoveFontMemResourceEx(Font);
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

{$IFDEF USE_NVIDIA_OPTIMUS}
// Включаем технологию nVidia Optimus:
function NvOptimusEnablement: LongWord; export;
begin
  Result := $00000001;
end;

exports NvOptimusEnablement;
{$ENDIF}

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

begin
  LoadResourceFont(hInstance, 'CALIBRI');
  LoadResourceFont(hInstance, 'CALIBRI_LIGHT');
  LoadResourceFont(hInstance, 'RALEWAY_REGULAR');

  {$WARNINGS OFF}
    SetPrecisionMode(pmSingle);
  {$WARNINGS ON}

  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
