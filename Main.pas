unit Main;

interface

{$I Definitions.inc}

uses
  // WinAPI:
  Windows, Messages, ShellAPI, PsAPI, hwid,

  // Delphi RTL:
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Math.Vectors, System.Math, System.NetEncoding,

  // FireMonkey:
  FMX.Platform.Win, FMX.Types    , FMX.Controls, FMX.Forms   , FMX.Graphics, FMX.Dialogs,
  FMX.TabControl  , FMX.Layouts  , FMX.StdCtrls, FMX.Objects , FMX.Controls.Presentation,
  FMX.Effects     , FMX.Edit     , FMX.Menus   , FMX.Ani     , FMX.Filter.Effects, FMX.Viewport3D,
  FMX.Controls3D  , FMX.Objects3D, FMX.Types3D , FMX.ExtCtrls, FMX.Layers3D, FMX.MaterialSources,

  // HoShiMin's API:
  FileAPI, FormatPE, PowerUP, RegistryUtils,

  // FLauncherAPI:
  LauncherAPI, Authorization, Registration, FilesValidation, ServerQuery,
  MinecraftLauncher, SkinSystem, JNIWrapper, AuxUtils, Encryption,

  // Synapse/OpenSSL:
  blcksock, ssl_openssl, ssl_openssl_lib,

  // AUX Modules:
  LauncherSettings, PopupManager, ServerPanel, StackCapacitor, ResUnpacker,
  System.ImageList, FMX.ImgList;

type
  TMainForm = class(TForm)
    MainTabControl: TTabControl;
    AuthTab: TTabItem;
    GameTab: TTabItem;
    SettingsTab: TTabItem;
    HeaderImage: TImage;
    CloseImage: TImage;
    SettingsImage: TImage;
    HideImage: TImage;
    StyleBook: TStyleBook;
    BigLogoImage: TImage;
    SmallLogoImage: TImage;
    ScrollBox: TVertScrollBox;
    DeauthLabel: TLabel;
    MainFormLayout: TLayout;
    FormShadowEffect: TShadowEffect;
    PlayButton: TButton;
    AuthButton: TButton;
    LoginEdit: TEdit;
    PasswordEdit: TEdit;
    HeaderLayout: TLayout;
    SkinPanel: TPanel;
    ServerPanelContainerSample: TPanel;
    ServerPreviewSample: TImage;
    ServerNameSample: TLabel;
    ServerInfoSample: TLabel;
    ServerProgressBarSample: TProgressBar;
    PreviewShadowSample: TShadowEffect;
    MonitoringLampSample: TCircle;
    LampGlowSample: TGlowEffect;
    MonitoringInfoSample: TLabel;
    CloseImageGlowEffect: TGlowEffect;
    HideImageGlowEffect: TGlowEffect;
    SettingsImageGlowEffect: TGlowEffect;
    ServersPopupMenu: TPopupMenu;
    OpenFolderItem: TMenuItem;
    UpdateClientItem: TMenuItem;
    Viewport3D: TViewport3D;
    StopButtonSample: TRectangle;
    PauseButtonSample: TPath;
    PauseButtonGlowSample: TGlowEffect;
    StopButtonGlowSample: TGlowEffect;
    DeleteClientItem: TMenuItem;
    HeadContainer: TDummy;
    HeadFront: TPlane;
    HeadLeft: TPlane;
    HeadRight: TPlane;
    HeadBack: TPlane;
    HeadBottom: TPlane;
    HeadTop: TPlane;
    ModelContainer: TDummy;
    TorsoContainer: TDummy;
    TorsoFront: TPlane;
    TorsoBack: TPlane;
    TorsoLeft: TPlane;
    TorsoRight: TPlane;
    TorsoTop: TPlane;
    TorsoBottom: TPlane;
    HelmetContainer: TDummy;
    HelmetFront: TPlane;
    HelmetBack: TPlane;
    HelmetLeft: TPlane;
    HelmetRight: TPlane;
    HelmetTop: TPlane;
    HelmetBottom: TPlane;
    RightLegContainer: TDummy;
    RightLegFront: TPlane;
    RightLegBack: TPlane;
    RightLegLeft: TPlane;
    RightLegRight: TPlane;
    RightLegTop: TPlane;
    RightLegBottom: TPlane;
    RightArmContainer: TDummy;
    RightArmFront: TPlane;
    RightArmBack: TPlane;
    RightArmLeft: TPlane;
    RightArmRight: TPlane;
    RightArmTop: TPlane;
    RightArmBottom: TPlane;
    LeftLegContainer: TDummy;
    LeftLegFront: TPlane;
    LeftLegBack: TPlane;
    LeftLegLeft: TPlane;
    LeftLegRight: TPlane;
    LeftLegTop: TPlane;
    LeftLegBottom: TPlane;
    LeftArmContainer: TDummy;
    LeftArmFront: TPlane;
    LeftArmBack: TPlane;
    LeftArmLeft: TPlane;
    LeftArmRight: TPlane;
    LeftArmTop: TPlane;
    LeftArmBottom: TPlane;
    Camera: TCamera;
    CloakContainer: TDummy;
    CloakFront: TPlane;
    CloakBack: TPlane;
    CloakLeft: TPlane;
    CloakRight: TPlane;
    CloakTop: TPlane;
    CloakBottom: TPlane;
    SkinPopupMenu: TPopupMenu;
    SkinItem: TMenuItem;
    CloakItem: TMenuItem;
    DrawHelmetItem: TMenuItem;
    SetupSkinItem: TMenuItem;
    DeletSkinItem: TMenuItem;
    DownloadSkinItem: TMenuItem;
    SetupCloakItem: TMenuItem;
    DeleteCloakItem: TMenuItem;
    DownloadCloakItem: TMenuItem;
    DrawCloakItem: TMenuItem;
    DrawWireframeItem: TMenuItem;
    Label1: TLabel;
    JVMPathEdit: TEdit;
    RAMEdit: TEdit;
    Label2: TLabel;
    JavaVersionEdit: TEdit;
    Label3: TLabel;
    BackButton: TButton;
    DeauthLabelHoverAnimation: TColorAnimation;
    PlotGrid: TPlotGrid;
    HardwareMonitoring: TTimer;
    CPUPath: TPath;
    CPUGlowEffect: TGlowEffect;
    Label4: TLabel;
    CPULoadingLabel: TLabel;
    Label5: TLabel;
    FreeRAMLabel: TLabel;
    Label7: TLabel;
    CPUFrequencyLabel: TLabel;
    Label9: TLabel;
    CPUFrequencyGlowEffect: TGlowEffect;
    CPUFrequencyColorAnimation: TColorAnimation;
    CPUFrequencyGlowAnimation: TFloatAnimation;
    RAMPath: TPath;
    RAMGlowEffect: TGlowEffect;
    CameraRotator: TFloatAnimation;
    RegLabel: TLabel;
    AutoLoginCheckbox: TCheckBox;
    WorkingFolderEdit: TEdit;
    Label6: TLabel;
    ServersPopupImageList: TImageList;

    procedure ShowErrorMessage(const Text: string);
    procedure ShowSuccessMessage(const Text: string);
    procedure ShowNullErrorMessage(const Text: string);
    procedure ShowNullSuccessMessage(const Text: string);

    procedure CloseImageClick(Sender: TObject);
    procedure HideImageClick(Sender: TObject);

    procedure FormCreate(Sender: TObject);

    procedure DrawSkin(const Bitmap: FMX.Graphics.TBitmap);
    procedure DrawCloak(const Bitmap: FMX.Graphics.TBitmap);

    procedure CreateMaterialSources;
    procedure DestroyMaterialSources;

    procedure OnPlaneRender(Sender: TObject; Context: TContext3D);
    procedure Viewport3DMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure Viewport3DMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure SkinPopupMenuPopup(Sender: TObject);
    procedure HeaderImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);

    procedure DrawHelmetItemClick(Sender: TObject);
    procedure DrawCloakItemClick(Sender: TObject);
    procedure DrawWireframeItemClick(Sender: TObject);

    procedure BackButtonClick(Sender: TObject);
    procedure SettingsImageClick(Sender: TObject);
    procedure DeauthLabelClick(Sender: TObject);
    procedure AuthButtonClick(Sender: TObject);
    procedure AddonItemClick(Sender: TObject);
    procedure OpenFolderItemClick(Sender: TObject);
    procedure UpdateClientItemClick(Sender: TObject);
    procedure DeleteClientItemClick(Sender: TObject);
    procedure OnDownload(ClientNumber: Integer; const DownloadInfo: TMultiLoaderDownloadInfo);
    procedure DeletSkinItemClick(Sender: TObject);
    procedure DownloadSkinItemClick(Sender: TObject);
    procedure SetupSkinItemClick(Sender: TObject);
    procedure DeleteCloakItemClick(Sender: TObject);
    procedure DownloadCloakItemClick(Sender: TObject);
    procedure SetupCloakItemClick(Sender: TObject);
    procedure PlayButtonClick(Sender: TObject);
    procedure ServersPopupMenuPopup(Sender: TObject);
    procedure HardwareMonitoringTimer(Sender: TObject);
    procedure PlotGridPaint(Sender: TObject; Canvas: TCanvas;
      const [Ref] ARect: TRectF);
    procedure Viewport3DMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Viewport3DMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure RegLabelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure WorkingFolderEditChangeTracking(Sender: TObject);
  private type
    TABS = (
      AUTH_TAB,
      GAME_TAB,
      SETTINGS_TAB
    );
  private const
    StacksCapacity: Integer = 300;
    SparsingCoeff: Integer = 5;
  private
    FLauncherAPI   : TLauncherAPI;
    FLastFrequency : ULONG;
    FIsAutoLogin   : Boolean;
    FIsRegPanel    : Boolean;
    FIsPopup       : Boolean;
    FIsDrag        : Boolean;
    FDrawWireframe : Boolean;
    FLastPoint     : TPointF;
    FSparsingCounter: Integer;
    FServerPanels  : array of TServerPanel;
    FSelectedClientNumber       : Integer;
    FSelectedToPlayClientNumber : Integer;
    FCPUStack, FRAMStack: TStackCapacitor<Single>;
    FLastCPUTimes: TThread.TSystemTimes;
    LastServer: String;
    function ShowOpenDialog(out SelectedPath: string; const Mask: string = ''): Boolean;
    function ShowSaveDialog(out SelectedPath: string; const Mask: string = ''; const InitialFileName: string = ''): Boolean;
    procedure SwitchTab(DesiredTab: TABS);
    procedure SelectClient(ClientNumber: Integer; SelectToPlay: Boolean = False);
    procedure SetAuthTabActiveState(State: Boolean);
    procedure OnSuccessfulAuth;
    {$IFDEF USE_MONITORING}
      procedure OnMonitoring(ServerNumber: Integer; const MonitoringInfo: TMonitoringInfo);
    {$ENDIF}
    procedure CheckSkinSystemErrors(Status: SKIN_SYSTEM_STATUS; ImageType: IMAGE_TYPE; const ErrorReason: string);
    procedure ValidateClient(ClientNumber: Integer; PlayAfterValidation: Boolean);
    procedure AttemptToLaunchClient;
    procedure LaunchClient(ClientNumber: Integer);
    procedure SaveSettings(AutoLogin, ExternalJava: Boolean);
    procedure LoadSettings;
    function EncryptPassword3(const Password: string): string;
    function DecryptPassword3(const PasswordBase64: string): string;
    function DecryptPassword2(const PasswordBase64: string): string;
    function DecryptPassword1(const PasswordBase64: string): string;
  public
    ComplexHwid: String;
  end;

var
  MainForm: TMainForm;


implementation

{$R *.fmx}

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

function TMainForm.EncryptPassword3(const Password: string): string;
begin
  Result := Password;
  EncryptDecryptVerrnam(Result, PAnsiChar(ComplexHwid), Length(ComplexHwid));
  Result := TNetEncoding.Base64.Encode(Result);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function TMainForm.DecryptPassword2(const PasswordBase64: string): string;
begin
  Result := PasswordBase64;
  try
    Result := TNetEncoding.Base64.Decode(Result);
    EncryptDecryptVerrnam(Result, PAnsiChar('COM' + ComplexHwid), Length('COM' + ComplexHwid));
  except
    Result := '';
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function TMainForm.DecryptPassword3(const PasswordBase64: string): string;
begin
  Result := PasswordBase64;
  try
    Result := TNetEncoding.Base64.Decode(Result);
    EncryptDecryptVerrnam(Result, PAnsiChar(ComplexHwid), Length(ComplexHwid));
  except
    Result := '';
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function TMainForm.DecryptPassword1(const PasswordBase64: string): string;
begin
  Result := PasswordBase64;
  try
    Result := TNetEncoding.Base64.Decode(Result);
    EncryptDecryptVerrnam(Result, PAnsiChar(PasswordKey), Length(PasswordKey));
  except
    Result := '';
  end;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.PlotGridPaint(Sender: TObject; Canvas: TCanvas;
  const [Ref] ARect: TRectF);
  function GetOffset(const Height, Percentage: Single): Single; inline;
  begin
    Result := (Height * (100 - Percentage)) / 100;
  end;
var
  Offset, Height: Single;
  I: Integer;
begin
  Offset := PlotGrid.Width / (StacksCapacity - 1);
  Height := PlotGrid.Height;

  CPUPath.Data.Clear;
  RAMPath.Data.Clear;

  CPUPath.Data.MoveTo(TPointF.Create(-1, Height));
  RAMPath.Data.MoveTo(TPointF.Create(-1, Height));

  for I := 0 to StacksCapacity - 1 do
  begin
    CPUPath.Data.LineTo(TPointF.Create(I * Offset, GetOffset(Height, FCPUStack.Items[I])));
    RAMPath.Data.LineTo(TPointF.Create(I * Offset, GetOffset(Height, FRAMStack.Items[I])));
  end;

  CPUPath.Data.LineTo(TPointF.Create((StacksCapacity - 1) * Offset, Height));
  CPUPath.Data.LineTo(TPointF.Create(0, Height));
  CPUPath.Data.LineTo(TPointF.Create(0, GetOffset(Height, FCPUStack.Items[0])));
  CPUPath.Data.LineTo(TPointF.Create(0, GetOffset(Height, FCPUStack.Items[0])));

  RAMPath.Data.LineTo(TPointF.Create((StacksCapacity - 1) * Offset, Height));
  RAMPath.Data.LineTo(TPointF.Create(0, Height));
  RAMPath.Data.LineTo(TPointF.Create(0, GetOffset(Height, FCPUStack.Items[0])));
  RAMPath.Data.LineTo(TPointF.Create(0, GetOffset(Height, FCPUStack.Items[0])));

  CPUPath.Data.ClosePath;
  RAMPath.Data.ClosePath;

  CPUPath.BringToFront;
  RAMPath.SendToBack;

  CPUGlowEffect.UpdateParentEffects;
  RAMGlowEffect.UpdateParentEffects;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.HardwareMonitoringTimer(Sender: TObject);
  function GetFreqString(Freq: ULONGLONG): string; inline;
  begin
    Result := FormatFloat('0.0', Freq / 1024) + ' ГГц'
  end;

  function GetMemString(Memory: ULONGLONG): string; inline;
  var
    MB: Single;
  begin
    MB := Memory / 1048576;
    if MB > 1024 then
      Result := FormatFloat('0.0', MB / 1024) + ' Гб'
    else
      Result := FormatFloat('0.0', MB) + ' Мб';
  end;
var
  CurrentCPUTimes: TThread.TSystemTimes;
  CPUUsage: Integer;
  CurrentFrequency: ULONG;
  MemoryStatusEx: _MEMORYSTATUSEX;
begin
  if FSparsingCounter = SparsingCoeff then
  begin
    MainTabControl.Tabs[Byte(SETTINGS_TAB)].BeginUpdate;

    // Загруженность ЦП:
    TThread.GetSystemTimes(CurrentCPUTimes);
    CPUUsage := TThread.GetCPUUsage(FLastCPUTimes);
    FCPUStack.Add(CPUUsage);
    FLastCPUTimes := CurrentCPUTimes;
    CPULoadingLabel.Text := IntToStr(CPUUsage) + '%';
    case CPUUsage of
      0..55   : CPULoadingLabel.FontColor := $FFFFFFFF;
      56..75  : CPULoadingLabel.FontColor := $FFDFA402;
      76..100 : CPULoadingLabel.FontColor := $FFFF0000;
    end;

    // Частота ЦП:
    CPUFrequencyLabel.BeginUpdate;
    CurrentFrequency := GetCPUFrequency;
    CPUFrequencyLabel.Text := GetFreqString(CurrentFrequency);
    if CurrentFrequency > FLastFrequency then
    begin
      CPUFrequencyGlowEffect.GlowColor      := $FF12FF00;
      CPUFrequencyColorAnimation.StartValue := $FF12FF00;
      CPUFrequencyColorAnimation.StopValue  := $FFFFFFFF;
      CPUFrequencyColorAnimation.Start;
      CPUFrequencyGlowAnimation.Start;
    end
    else if CurrentFrequency < FLastFrequency then
    begin
      CPUFrequencyGlowEffect.GlowColor      := $FFFF0000;
      CPUFrequencyColorAnimation.StartValue := $FFFF0000;
      CPUFrequencyColorAnimation.StopValue  := $FFFFFFFF;
      CPUFrequencyColorAnimation.Start;
      CPUFrequencyGlowAnimation.Start;
    end;
    FLastFrequency := CurrentFrequency;
    CPUFrequencyLabel.EndUpdate;

    MemoryStatusEx.dwLength := SizeOf(MemoryStatusEx);
    GlobalMemoryStatusEx(MemoryStatusEx);
    FreeRAMLabel.Text := GetMemString(MemoryStatusEx.ullAvailPhys);
    FRAMStack.Add(MemoryStatusEx.dwMemoryLoad);
    case MemoryStatusEx.dwMemoryLoad of
      0..55   : FreeRAMLabel.FontColor := $FFFFFFFF;
      56..75  : FreeRAMLabel.FontColor := $FFDFA402;
      76..100 : FreeRAMLabel.FontColor := $FFFF0000;
    end;

    MainTabControl.Tabs[Byte(SETTINGS_TAB)].EndUpdate;

    FSparsingCounter := 0;
  end
  else
  begin
    FCPUStack.Add(FCPUStack.Items[StacksCapacity - 1]);
    FRAMStack.Add(FRAMStack.Items[StacksCapacity - 1]);
    Inc(FSparsingCounter);
  end;

  PlotGrid.Repaint;
end;




//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                        Вспомогательные функции
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

function GetFmxWND(const WindowHandle: TWindowHandle): THandle; inline;
begin
  Result := WindowHandleToPlatform(WindowHandle).Wnd
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.ShowNullErrorMessage(const Text: string);
begin
  MessageBox(0, PChar(Text), 'Ошибка!', MB_ICONERROR);
  ExitProcess(0);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.ShowNullSuccessMessage(const Text: string);
begin
  MessageBox(0, PChar(Text), 'Успешно!', MB_ICONASTERISK);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.ShowErrorMessage(const Text: string);
begin
  MessageBox(GetFmxWND(Handle), PChar(Text), 'Ошибка!', MB_ICONERROR);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.ShowSuccessMessage(const Text: string);
begin
  MessageBox(GetFmxWND(Handle), PChar(Text), 'Успешно!', MB_ICONASTERISK);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function TMainForm.ShowOpenDialog(out SelectedPath: string; const Mask: string = ''): Boolean;
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(MainForm);
  OpenDialog.Filter := Mask;
  Result := OpenDialog.Execute;
  if Result then SelectedPath := OpenDialog.FileName;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function TMainForm.ShowSaveDialog(out SelectedPath: string; const Mask: string = ''; const InitialFileName: string = ''): Boolean;
var
  SaveDialog: TOpenDialog;
begin
  SaveDialog := TOpenDialog.Create(MainForm);
  SaveDialog.Filter := Mask;
  SaveDialog.FileName := InitialFileName;
  Result := SaveDialog.Execute;
  if Result then SelectedPath := SaveDialog.FileName;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.SelectClient(ClientNumber: Integer; SelectToPlay: Boolean = False);
var
  I: Integer;
begin
  if (ClientNumber < 0) or (FLauncherAPI.Clients.Count = 0) or (ClientNumber >= FLauncherAPI.Clients.Count) then Exit;

  FSelectedClientNumber := ClientNumber;
  if SelectToPlay then FSelectedToPlayClientNumber := ClientNumber;

  ScrollBox.BeginUpdate;
  for I := 0 to FLauncherAPI.Clients.Count - 1 do
  begin
    if I <> ClientNumber then
    begin
      if SelectToPlay then
        FServerPanels[I].SetDisabledView
      else
        FServerPanels[I].SetNormalView;
    end
    else
    begin
      FServerPanels[I].SetSelectedView;
    end;
  end;
  ScrollBox.EndUpdate;
  ScrollBox.Repaint;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = VK_RETURN then case MainTabControl.TabIndex of
    Integer(AUTH_TAB): AuthButton.OnClick(Self);
    Integer(GAME_TAB): PlayButton.OnClick(Self);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.WorkingFolderEditChangeTracking(Sender: TObject);
begin
  if Assigned(FLauncherAPI) then
  begin
    FLauncherAPI.LocalWorkingFolder := WorkingFolderEdit.Text;
    SaveSettings(AutoLoginCheckbox.IsChecked, FLauncherAPI.JavaInfo.ExternalJava);
    if not FLauncherAPI.JavaInfo.ExternalJava then
      JVMPathEdit.Text := FLauncherAPI.LocalWorkingFolder + '\' + FLauncherAPI.JavaInfo.JavaParameters.JavaFolder + '\' + FLauncherAPI.JavaInfo.JavaParameters.JVMPath;
  end;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                          Сохранение настроек
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.SaveSettings(AutoLogin, ExternalJava: Boolean);
begin
  SaveStringToRegistry(RegistryPath, 'Login', LoginEdit.Text);

  if AutoLogin then
    SaveStringToRegistry(RegistryPath, 'Password', EncryptPassword3(PasswordEdit.Text))
  else
    SaveStringToRegistry(RegistryPath, 'Password', '');

  SaveNumberToRegistry(RegistryPath, 'PasswordEncryptionVersion', 3);

  if ExternalJava then
  begin
    {$IFDEF CPUX64}
      SaveStringToRegistry(RegistryPath, 'JavaVersion64', JavaVersionEdit.Text);
      SaveStringToRegistry(RegistryPath, 'JVMPath64'    , JVMPathEdit.Text);
    {$ELSE}
      SaveStringToRegistry(RegistryPath, 'JavaVersion32', JavaVersionEdit.Text);
      SaveStringToRegistry(RegistryPath, 'JVMPath32'    , JVMPathEdit.Text);
    {$ENDIF}
  end;
  SaveStringToRegistry(RegistryPath, {$IFDEF CPUX64}'RAM64'{$ELSE}'RAM32'{$ENDIF}, RAMEdit.Text);
  SaveBooleanToRegistry(RegistryPath, 'AutoLogin', AutoLogin);
  SaveStringToRegistry(RegistryPath, 'WorkingFolder', WorkingFolderEdit.Text);
  SaveStringToRegistry(RegistryPath, 'LastServer', LastServer);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.LoadSettings;
  function GetJavaLowVersion(const FullVersion: string): string; inline;
  var
    DelimiterPos, FullVersionLength: Integer;
  begin
    FullVersionLength := Length(FullVersion);
    if FullVersionLength = 0 then Exit('');

    DelimiterPos := Pos('.', FullVersion);
    if DelimiterPos = 0 then Exit(FullVersion);

    Result := Copy(FullVersion, DelimiterPos + 1, FullVersionLength - DelimiterPos);
  end;
var
  JavaHome, LibPath, JavaVersion: string;
begin
  GetCurrentJavaInfo(JavaHome, LibPath, JavaVersion);
  JavaVersion := GetJavaLowVersion(JavaVersion);

  LoginEdit.Text    := ReadStringFromRegistry(RegistryPath, 'Login'   , LoginEdit.Text);
  if ReadNumberFromRegistry(RegistryPath, 'PasswordEncryptionVersion', 1) = 1 then
    PasswordEdit.Text := DecryptPassword1(ReadStringFromRegistry(RegistryPath, 'Password', ''));
  if ReadNumberFromRegistry(RegistryPath, 'PasswordEncryptionVersion', 1) = 2 then
    PasswordEdit.Text := DecryptPassword2(ReadStringFromRegistry(RegistryPath, 'Password', ''));
  if ReadNumberFromRegistry(RegistryPath, 'PasswordEncryptionVersion', 1) = 3 then
    PasswordEdit.Text := DecryptPassword3(ReadStringFromRegistry(RegistryPath, 'Password', ''));
  {$IFDEF CPUX64}
    RAMEdit.Text         := ReadStringFromRegistry(RegistryPath, 'RAM64'        , RAMEdit.Text);
    JavaVersionEdit.Text := ReadStringFromRegistry(RegistryPath, 'JavaVersion64', JavaVersion);
    JVMPathEdit.Text     := ReadStringFromRegistry(RegistryPath, 'JVMPath64'    , LibPath);
  {$ELSE}
    RAMEdit.Text         := ReadStringFromRegistry(RegistryPath, 'RAM32'        , RAMEdit.Text);
    JavaVersionEdit.Text := ReadStringFromRegistry(RegistryPath, 'JavaVersion32', JavaVersion);
    JVMPathEdit.Text     := ReadStringFromRegistry(RegistryPath, 'JVMPath32'    , LibPath);
  {$ENDIF}
  FIsAutoLogin := ReadBooleanFromRegistry(RegistryPath, 'AutoLogin', False);
  WorkingFolderEdit.Text := ReadStringFromRegistry(RegistryPath, 'WorkingFolder', GetSpecialFolderPath(CSIDL_APPDATA) + '\' + LocalWorkingFolder);
  LastServer := ReadStringFromRegistry(RegistryPath, 'LastServer', '');
  AutoLoginCheckbox.IsChecked := FIsAutoLogin;
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                      Функционал панели заголовка
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.CloseImageClick(Sender: TObject);
begin
  ExitProcess(0);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.HideImageClick(Sender: TObject);
begin
  ShowWindow(GetFmxWND(MainForm.Handle), SW_MINIMIZE);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.HeaderImageMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
const
  SC_DRAGMOVE = $F012;
begin
  if ssLeft in Shift then
  begin
    FIsDrag := True;
    MainForm.BeginUpdate;
    ReleaseCapture;
    SendMessage(GetFmxWND(Self.Handle), WM_SYSCOMMAND, SC_DRAGMOVE, 0);
    MainForm.EndUpdate;
    FIsDrag := False;
  end;
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                  Обработка переходов между вкладками
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.SwitchTab(DesiredTab: TABS);
var
  TabIndex: Byte;
begin
  TabIndex := Byte(DesiredTab);
  MainTabControl.BeginUpdate;
  MainTabControl.TabIndex := TabIndex;
  MainTabControl.UpdateEffects;
  MainTabControl.EndUpdate;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeauthLabelClick(Sender: TObject);
var
  I, ServerPanelsCount: Integer;
begin
  // Сохраняем настройки:
  FIsAutoLogin := False;
  AutoLoginCheckbox.IsChecked := FIsAutoLogin;
  SaveSettings(FIsAutoLogin, FLauncherAPI.JavaInfo.ExternalJava);

  MainFormLayout.BeginUpdate;

  DestroyMaterialSources;
  FLauncherAPI.Deauthorize;

  // Чистим список панелек серверов:
  ServerPanelsCount := Length(FServerPanels);
  if ServerPanelsCount > 0 then for I := 0 to ServerPanelsCount - 1 do
  begin
    FreeAndNil(FServerPanels[I]);
  end;
  SetLength(FServerPanels, 0);

  // Показываем шаблон панельки сервера - для последующей генерации он нужен нам видимым:
  ServerPanelContainerSample.Visible := True;

  PlayButton.Enabled := True;
  DeauthLabel.Visible := False;
  SwitchTab(AUTH_TAB);

  MainFormLayout.EndUpdate;
  MainFormLayout.Repaint;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.SettingsImageClick(Sender: TObject);
begin
  if not FLauncherAPI.IsAuthorized then
  begin
    ShowErrorMessage('Авторизуйтесь для доступа к настройкам!');
    Exit;
  end;

  case MainTabControl.TabIndex of
    Byte(GAME_TAB)     : SwitchTab(SETTINGS_TAB);
    Byte(SETTINGS_TAB) : SwitchTab(GAME_TAB);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.BackButtonClick(Sender: TObject);
begin
  SwitchTab(GAME_TAB);
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH



procedure TMainForm.FormCreate(Sender: TObject);
begin
  ComplexHwid := GetComplexHwid();
  
  // Чистим папку от временных файлов:
  DeleteDirectory('*.old', True);

  // Запускаем системный мониторинг:
  FCPUStack := TStackCapacitor<Single>.Create(StacksCapacity, 0);
  FRAMStack := TStackCapacitor<Single>.Create(StacksCapacity, 0);
  TThread.GetSystemTimes(FLastCPUTimes);
  HardwareMonitoring.Enabled := True;

  // Готовим окружение:
  FormatSettings.DecimalSeparator := '.';
  DeauthLabel.Visible := False;
  FIsRegPanel := False;
  SwitchTab(AUTH_TAB);

  // Загружаем настройки:
  LoadSettings;

  // Настраиваем камеру:
{
  // Если камера вне контейнера ModelContainer:
  Camera.RotationCenter.X := ModelContainer.Position.X;
  Camera.RotationCenter.Y := ModelContainer.Position.Y;
  Camera.RotationCenter.Z := ModelContainer.Position.Z - Camera.Position.Z;
}
{
  // Если камера внутри контейнера ModelContainer:
  Camera.RotationCenter.X := - Camera.Position.X;
  Camera.RotationCenter.Y := - Camera.Position.Y;
  Camera.RotationCenter.Z := - Camera.Position.Z;
}
  // Создаём объект FLauncherAPI:
  FLauncherAPI := TLauncherAPI.Create(WorkingFolderEdit.Text, ServerWorkingFolder, ServerWorkingFolderDownload);
  FLauncherAPI.EncryptionKey := EncryptionKey;
  FLauncherAPI.LauncherInfo.LauncherVersion := LauncherVersion;

  // Распаковываем необходимые ресурсы:
  {$IFDEF USE_SSL}
    {$IFDEF CPUX64}
      UnpackRes('LIBEAY64', FLauncherAPI.LocalWorkingFolder + '\OpenSSL\x64\libeay32.dll');
      UnpackRes('SSLEAY64', FLauncherAPI.LocalWorkingFolder + '\OpenSSL\x64\ssleay32.dll');
      SetDllDirectory(PChar(FLauncherAPI.LocalWorkingFolder + '\OpenSSL\x64\'));
    {$ELSE}
      UnpackRes('LIBEAY32', FLauncherAPI.LocalWorkingFolder + '\OpenSSL\x32\libeay32.dll');
      UnpackRes('SSLEAY32', FLauncherAPI.LocalWorkingFolder + '\OpenSSL\x32\ssleay32.dll');
      SetDllDirectory(PChar(FLauncherAPI.LocalWorkingFolder + '\OpenSSL\x32\'));
    {$ENDIF}

    if InitSSLInterface then
      SSLImplementation := TSSLOpenSSL;
  {$ENDIF}

  if FIsAutoLogin then
    AuthButton.OnClick(Self);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                         Авторизация/Регистрация
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.SetAuthTabActiveState(State: Boolean);
begin
  MainTabControl.Tabs[Byte(AUTH_TAB)].BeginUpdate;
  LoginEdit.Enabled         := State;
  PasswordEdit.Enabled      := State;
  AuthButton.Enabled        := State;
  AutoLoginCheckbox.Enabled := State;
  RegLabel.Enabled          := State;
  MainTabControl.Tabs[Byte(AUTH_TAB)].EndUpdate;
  MainTabControl.Tabs[Byte(AUTH_TAB)].Repaint;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.RegLabelClick(Sender: TObject);
begin
  if RegisterLink <> '' then
    begin
      //Регистрация на сайте: открываем браузер
      ShellExecute(0, Nil, PWideChar(RegisterLink), Nil, Nil, SW_NORMAL);
    end else
    begin
      //Регистрация через лаунчер:
      FIsRegPanel := not FIsRegPanel;
      if FIsRegPanel then
      begin
        AuthButton.Text := 'Зарегистрироваться';
        RegLabel.Text   := 'Авторизация';
      end
      else
      begin
        AuthButton.Text := 'Авторизоваться';
        RegLabel.Text   := 'Регистрация';
      end;
    end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.AuthButtonClick(Sender: TObject);
begin
  SetAuthTabActiveState(False);
  if not FIsRegPanel then
  begin
    FLauncherAPI.Authorize(
                            LoginEdit.Text,
                            PasswordEdit.Text,
                            True,
                            procedure(const AuthStatus: AUTH_STATUS)
                            begin
                              SetAuthTabActiveState(True);
                              if AuthStatus.StatusCode = AUTH_STATUS_SUCCESS then
                              begin
                                OnSuccessfulAuth;
                                SwitchTab(GAME_TAB);
                              end
                              else
                              begin
                                ShowErrorMessage('[' + IntToStr(Integer(AuthStatus.StatusCode)) + '] ' + AuthStatus.StatusString);
                              end;
                            end
                           );
  end
  else
  begin
    FLauncherAPI.RegisterPlayer(LoginEdit.Text, PasswordEdit.Text, True, procedure(const RegStatus: REG_STATUS)
    begin
      SetAuthTabActiveState(True);
      if RegStatus.StatusCode = REG_STATUS_SUCCESS then
      begin
        ShowSuccessMessage('Успешная регистрация!');
        RegLabel.OnClick(Self);
      end
      else
      begin
        ShowErrorMessage('[' + IntToStr(Integer(RegStatus.StatusCode)) + '] ' + RegStatus.StatusString);
      end;
    end);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.OnSuccessfulAuth;
var
  ServerPanelSample: TServerPanel.TServerPanelSample;
  ServerPanel: TServerPanel;
  Client: TMinecraftLauncher;
  PopupBinder: TPopupMenuBinder;
  I, J: Integer;
  ClientToSelect: Integer;
  AddonsCount: Integer;
  TempMenuItem: TMenuItem;
  ImgSize: TSizeF;
begin
  // Сохраняем настройки:
  FIsAutoLogin := AutoLoginCheckbox.IsChecked;
  SaveSettings(FIsAutoLogin, FLauncherAPI.JavaInfo.ExternalJava);

  // Проверяем версию лаунчера:
  if not FLauncherAPI.LauncherInfo.IsLauncherValid(False) then
  begin
    if MessageBox(GetFmxWND(MainForm.Handle), 'Требуется обновление лаунчера! Обновить сейчас?', 'Внимание!', MB_ICONQUESTION + MB_YESNO) = ID_YES then
    begin
      if not FLauncherAPI.LauncherInfo.UpdateLauncher then
      begin
        ShowErrorMessage('Не получилось обновить лаунчер!' + #13#10 + 'Попробуйте снова через несколько минут или скачайте новый лаунчер вручную.');
        ExitProcess(0);
      end;
    end
    else
    begin
      ShowErrorMessage('Обновите лаунчер для продолжения!');
      ExitProcess(0);
    end;
  end;

  FSelectedClientNumber       := -1;
  FSelectedToPlayClientNumber := -1;

  MainFormLayout.BeginUpdate;

  DeauthLabel.Visible := True;

  // Создаём шаблон записи в списке серверов:
  ServerPanelSample.ServerPanel           := ServerPanelContainerSample;
  ServerPanelSample.NameLabel             := ServerNameSample;
  ServerPanelSample.InfoLabel             := ServerInfoSample;
  ServerPanelSample.ProgressBar           := ServerProgressBarSample;
  ServerPanelSample.PreviewImage          := ServerPreviewSample;
  ServerPanelSample.MonitoringLamp        := MonitoringLampSample;
  ServerPanelSample.MonitoringInfo        := MonitoringInfoSample;
  ServerPanelSample.PreviewShadowEffect   := PreviewShadowSample;
  ServerPanelSample.LampGlowEffect        := LampGlowSample;
  ServerPanelSample.PauseButton           := PauseButtonSample;
  ServerPanelSample.PauseButtonGlowEffect := PauseButtonGlowSample;
  ServerPanelSample.StopButton            := StopButtonSample;
  ServerPanelSample.StopButtonGlowEffect  := StopButtonGlowSample;

  {$IFNDEF USE_MONITORING}
    ServerPanelSample.MonitoringLamp.Visible := False; // Делаем невидимой лампочку мониторинга
  {$ENDIF}

  // Создаём список серверов, привязываем события:
  if FLauncherAPI.Clients.Count > 0 then
  begin
    ClientToSelect := 0;
    SetLength(FServerPanels, FLauncherAPI.Clients.Count);
    for I := 0 to FLauncherAPI.Clients.Count - 1 do
    begin
      Client := FLauncherAPI.Clients.ClientsArray[I];

      // Создаём панельку сервера:
      FServerPanels[I] := TServerPanel.Create(ScrollBox, ServerPanelSample, I);
      ServerPanel := FServerPanels[I];
      ServerPanel.Content.NameLabel.Text := Client.ServerInfo.Name;
      ServerPanel.Content.InfoLabel.Text := Client.ServerInfo.Info;
      if Client.HasPreview then
        ServerPanel.Content.PreviewImage.Bitmap := Client.PreviewBitmap;

      ServerPanel.OnClick := procedure(const Sender: TServerPanel)
      begin
        SelectClient(Sender.Number);
      end;

      ServerPanel.OnDblClick := procedure(const Sender: TServerPanel)
      begin
        SelectClient(Sender.Number);
        AttemptToLaunchClient;
      end;

      ServerPanel.OnPauseClick := procedure(const Sender: TServerPanel)
      begin
        if Sender.ResumeState then
        begin
          FLauncherAPI.Clients.ClientsArray[Sender.Number].MultiLoader.Resume;
          Sender.ShowPauseButton;
        end
        else
        begin
          FLauncherAPI.Clients.ClientsArray[Sender.Number].MultiLoader.Pause;
          Sender.Content.ServerPanel.BeginUpdate;
          Sender.Content.InfoLabel.Text := 'Загрузка приостановлена';
          Sender.ShowResumeButton;
          Sender.Content.ServerPanel.EndUpdate;
          Sender.Content.ServerPanel.Repaint;
        end;
      end;

      ServerPanel.OnStopClick := procedure(const Sender: TServerPanel)
      begin
        FLauncherAPI.Clients.ClientsArray[Sender.Number].MultiLoader.Cancel;
        Sender.Content.ServerPanel.BeginUpdate;
        Sender.Content.InfoLabel.Text := 'Остановка загрузки...';
        Sender.ShowPauseButton;
        Sender.DisableDownloadButtons;
        Sender.Content.ServerPanel.EndUpdate;
        Sender.Content.ServerPanel.Repaint;
      end;

      // Создаём всплывающее меню по образцу
      PopupBinder := TPopupMenuBinder.Create(ServersPopupMenu);

      ImgSize := TSizeF.Create(16, 16);
      // Добавляем аддоны в меню
      AddonsCount := Length(Client.ServerInfo.Addons);
      if AddonsCount > 0 then
      begin
        // Добавляем разделитель
        TempMenuItem := TMenuItem.Create(nil);
        TempMenuItem.Text := '-';
        PopupBinder.AddItem(TempMenuItem);

        // Добавляем кнопки для каждого аддона
        for J := 0 to AddonsCount-1 do
        begin
           TempMenuItem := TMenuItem.Create(nil);

           TempMenuItem.Text := Client.ServerInfo.Addons[J].Id;
           if Client.ServerInfo.Addons[J].Name <> '' then
             TempMenuItem.Text := Client.ServerInfo.Addons[J].Name;
           TempMenuItem.TagString := Client.ServerInfo.Addons[J].Id;
           TempMenuItem.IsChecked := ReadBooleanFromRegistry(RegistryPath, 'addon_' + Client.ServerInfo.Addons[J].Id, Client.ServerInfo.Addons[J].Enabled);
           if TempMenuItem.IsChecked then
             TempMenuItem.Bitmap := ServersPopupImageList.Bitmap(ImgSize, 1) else
             TempMenuItem.Bitmap := ServersPopupImageList.Bitmap(ImgSize, 0);
           TempMenuItem.OnClick := AddonItemClick;

           PopupBinder.AddItem(TempMenuItem);
        end;
      end;
      // Цепляем к серверу всплывающее меню:
      PopupBinder.Bind(ServerPanel.Content.ServerPanel, I);

      // Проверяем, нужно ли его выделить
      if LastServer = Client.ServerInfo.Name then
         ClientToSelect := I;
    end;

    // Выделяем нужный сервер в списке:
    SelectClient(ClientToSelect);

  end;

  // Скрываем шаблон списка серверов, он нам больше не нужен:
  ServerPanelContainerSample.Visible := False;

  // Настраиваем углы поворота модельки:
  ModelContainer.ResetRotationAngle;
  ModelContainer.RotationAngle.Y  := 25;
  CloakContainer.RotationCenter.Y := -3;
  CloakContainer.RotationAngle.X  := -7;

  // Рисуем скин и плащ:
  CreateMaterialSources;
  DrawSkin(FLauncherAPI.UserInfo.SkinBitmap);
  DrawCloak(FLauncherAPI.UserInfo.CloakBitmap);

  // Выставляем панель настроек:
  if not FLauncherAPI.JavaInfo.ExternalJava then
  begin
    JVMPathEdit.Text     := FLauncherAPI.LocalWorkingFolder + '\' + FLauncherAPI.JavaInfo.JavaParameters.JavaFolder + '\' + FLauncherAPI.JavaInfo.JavaParameters.JVMPath;
    JavaVersionEdit.Text := FLauncherAPI.JavaInfo.JavaParameters.JavaVersion.ToString;
    JVMPathEdit.Enabled     := False;
    JavaVersionEdit.Enabled := False;
  end;

  MainFormLayout.EndUpdate;
  MainFormLayout.Repaint;

  // Запускаем мониторинг:
  {$IFDEF USE_MONITORING}
    FLauncherAPI.StartMonitoring(MonitoringInterval, OnMonitoring);
  {$ENDIF}
end;




//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                   Проверка, обновление и запуск клиента
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


function CheatEngineLaunchedMem(): boolean;

const
  SearchMask: array[0..11] of char = 'Cheat Engine';
  MinMatches: Integer = 50;
  MaxProcessesBufferSize: Cardinal = 1024 * 16;
  MaxDataBufferSize: Cardinal = 1024 * 1024;
  MaxProcessCheckBytes: Cardinal = 1024 * 1024 * 20;

var
  j, BytesRead, InProcessAddr, CheckedBytes, NeededDataBufferSize, CurDataBufferSize, InPageAddr, LastPageAddr: NativeUInt;
  i, cntProcesses, SearchIndex, MaskLength, CurMatches: Integer;
  MyProcessID, ReturnedProcessesBufferSize: DWORD;
  PidProcesses, PidWork: PDWORD;
  Mbi: TMemoryBasicInformation;
  ProcessHandle: THandle;
  Buf: PChar;


begin
MaskLength := length(SearchMask);
MyProcessID := GetCurrentProcessId;
result := false;
ReturnedProcessesBufferSize := 0;
GetMem(PidProcesses, MaxProcessesBufferSize);
GetMem(Buf, MaxDataBufferSize);
if Assigned(PidProcesses) then
  begin
  try
  if EnumProcesses(PidProcesses, MaxProcessesBufferSize, ReturnedProcessesBufferSize) then
    begin
    cntProcesses := ReturnedProcessesBufferSize div sizeof(DWORD);
    PidWork := PidProcesses;
    for i := 0 to cntProcesses - 1 do
      begin
      if (MyProcessID <> PidWork^) then
        begin
        ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, false, PidWork^);
        if ProcessHandle <> 0 then
          try
          CheckedBytes := 0;
          SearchIndex := 0;
          CurMatches := 0;
          InProcessAddr := 0;
          while (VirtualQueryEx(ProcessHandle, Pointer(InProcessAddr), Mbi, SizeOf(Mbi)) <> 0) do
            begin
            application.ProcessMessages;
            if (Mbi.State = MEM_COMMIT) and not ((Mbi.Protect and PAGE_GUARD) = PAGE_GUARD) then
              begin
              try
                InPageAddr := NativeUInt(Mbi.BaseAddress);
                LastPageAddr := InPageAddr + Mbi.RegionSize;
                while (CheckedBytes < MaxProcessCheckBytes) and (InPageAddr < LastPageAddr) do
                  begin
                  NeededDataBufferSize := Mbi.RegionSize - NativeUInt(InPageAddr) + NativeUInt(Mbi.BaseAddress);
                  if (NeededDataBufferSize > MaxDataBufferSize) then
                    CurDataBufferSize := MaxDataBufferSize else
                    CurDataBufferSize := NeededDataBufferSize;
                    if ReadProcessMemory(ProcessHandle, Pointer(InPageAddr), Buf, CurDataBufferSize, BytesRead) then
                      begin
                      CheckedBytes := CheckedBytes + BytesRead;
                      for j := 0 to BytesRead - 1 do
                        begin
                        if (Buf[j] = SearchMask[SearchIndex]) then
                          begin
                          inc(SearchIndex);
                          if (SearchIndex >= MaskLength) then
                            begin
                            SearchIndex := 0;
                            inc(CurMatches);
                            if CurMatches >= MinMatches then
                              begin
                              result := true;
                              exit;
                              end;
                            end;
                          end else
                            SearchIndex := 0;
                        end;
                      end;
                    InPageAddr := InPageAddr + CurDataBufferSize;
                    end;
              except
              end;
              end;
            InProcessAddr := InProcessAddr + Mbi.RegionSize;
            end;
          finally
          CloseHandle(ProcessHandle);
          end;
        end;
      Inc(PidWork);
      end;
    end;
  finally
  FreeMem(PidProcesses, MaxProcessesBufferSize);
  FreeMem(Buf);
  end;
  end;
end;



function CheatEngineLaunchedWin(): boolean;

var IsLaunched: boolean;

function EnWndCallBack(FormHandle:hWnd; lParam: LPARAM):boolean; stdcall;
var  FormCaption: array[0..255] of Char;
CapStr:string;
begin
Result:=True;
GetWindowText(FormHandle,FormCaption,SizeOf(FormCaption));
CapStr := FormCaption;
if (pos('Cheat Engine', CapStr) > 0) then
  IsLaunched := true;
end;


begin
IsLaunched := false;
EnumWindows(@EnWndCallBack,0);
Result := IsLaunched;
end;

// Комбинированная защита от читеров
procedure AntiCheatThread();
var
  a,b,c:integer;
  ver: string;
  CELauncherFw: boolean;
  CELaunchedMem: boolean;
  CELaunchedWin: boolean;
begin
  while (true) do
    begin
    try
    CELaunchedMem := false;
    for a:=1 to 7 do
      for b:=-1 to 9 do
        for c:=-1 to 3 do
          if not((c=0) or (a < 5) and (c >= 0)) then
            begin
            ver := inttostr(a);
            if (b>=0) then ver := ver + '.' + inttostr(b);
            if (c>=0) then ver := ver + '.' + inttostr(c);
            if Windows.FindWindow(nil,pchar('Cheat Engine ' + ver)) <> 0 then
              CELaunchedMem := true;
            end;

    CELaunchedMem := CheatEngineLaunchedMem();
    CELaunchedWin := CheatEngineLaunchedWin();
    except
    end;

    if (CELauncherFw or CELaunchedMem or CELaunchedWin) then
      begin
      MessageBoxTimeout(0,
                       PChar(
                              'Обнаружен Cheat Engine.' + #13#10 +
                              'Пожалуйста, удалите Cheat Engine с компьютера.'
                             ),
                       'Обнаружен чит!',
                       MB_ICONERROR,
                       0,
                       5000
                      );
      ExitProcess(0);
      end;


    sleep(120000);
    end;

end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.LaunchClient(ClientNumber: Integer);
var
  Status: JNI_RETURN_VALUES;
  JVMPath: string;
begin
  PlayButton.Enabled := True;

  // Получаем путь к джаве:
  if FLauncherAPI.JavaInfo.ExternalJava then
  begin
    JVMPath := JVMPathEdit.Text;
    FLauncherAPI.JavaInfo.SetJVMPath(JVMPath, StrToInt(JavaVersionEdit.Text));
  end
  else
  begin
    JVMPath := FLauncherAPI.LocalWorkingFolder + '\' +
               FLauncherAPI.JavaInfo.JavaParameters.JavaFolder + '\' +
               FLauncherAPI.JavaInfo.JavaParameters.JVMPath;
  end;

  // Проверяем, что путь верный:
  if not FileExists(JVMPath) then
  begin
    ShowErrorMessage('Библиотека jvm.dll не найдена по расположению:' + #13#10 + JVMPath);
    Exit;
  end;

  // Убеждаемся, что указанный файл - библиотека:
  if GetPEType(JVMPath) <> peDll then
  begin
    ShowErrorMessage('Указанный в настройках файл - не DLL!' + #13#10 + 'Укажите корректный путь к jvm.dll!');
    Exit;
  end;

  // Убеждаемся, что разрядность библиотеки соответствует разрядности лаунчера:
  if GetPEMachineType(JVMPath) <> {$IFDEF CPUX64}mt64Bit{$ELSE}mt32Bit{$ENDIF} then
  begin
    ShowErrorMessage('Неверная разрядность jvm.dll!' + #13#10 + 'Разрядность библиотеки должна соответствовать разрядности лаунчера!');
    Exit;
  end;

  // Убеждаемся, что jvm ещё нет в процессе:
  if GetModuleHandle('jvm.dll') <> 0 then
  begin
    ShowErrorMessage('В процесс загружена неизвестная JVM!' + #13#10 + 'Продолжение невозможно!');
    Exit;
  end;

  // Запоминаем последний запущенный сервер
  LastServer := FLauncherAPI.Clients.ClientsArray[ClientNumber].ServerInfo.Name;

  // Сохраняем настройки:
  SaveSettings(FIsAutoLogin, FLauncherAPI.JavaInfo.ExternalJava);

  HardwareMonitoring.Enabled := False; // Отключаем системный мониторинг
  FLauncherAPI.StopMonitoring; // Отключаем мониторинг

  // Скрываем форму лаунчера:
  ShowWindow(GetFmxWND(MainForm.Handle), SW_HIDE);
  ShowWindow(ApplicationHWND, SW_HIDE);

  {$IFDEF FLUSH_JVM_FLAGS}
    SetEnvironmentVariable('_JAVA_OPTIONS', '');
    SetEnvironmentVariable('JAVA_TOOL_OPTIONS', '');
  {$ENDIF}

  // Запускаем поток проверки на наличие читов
  TThread.CreateAnonymousThread(AntiCheatThread).Start;

  // Запускаем игру:
  Status := FLauncherAPI.LaunchClient(
                                      ClientNumber,
                                      StrToInt(RAMEdit.Text),
                                      {$IFDEF USE_JVM_OPTIMIZATION}True{$ELSE}False{$ENDIF},
                                      {$IFDEF USE_JVM_EXPERIMENTAL_FEATURES}True{$ELSE}False{$ENDIF}
                                     );
  case Status of
    JNIWRAPPER_UNKNOWN_ERROR       : ShowNullErrorMessage('Неизвестная ошибка в JVM!');
    JNIWRAPPER_JNI_INVALID_VERSION : ShowNullErrorMessage('Неверная версия JNI!');
    JNIWRAPPER_NOT_ENOUGH_MEMORY   : ShowNullErrorMessage('Недостаточно оперативной памяти для запуска JVM!');
    JNIWRAPPER_JVM_ALREADY_EXISTS  : ShowNullErrorMessage('JVM уже существует! Нельзя запустить две и более JVM в одном процессе!');
    JNIWRAPPER_INVALID_ARGUMENTS   : ShowNullErrorMessage('Неверные аргументы JVM!');
    JNIWRAPPER_CLASS_NOT_FOUND     : ShowNullErrorMessage('Класс не найден!');
    JNIWRAPPER_METHOD_NOT_FOUND    : ShowNullErrorMessage('Метод не найден!');
  else
    {$IFDEF INGAME_FILES_MONITORING}
      FLauncherAPI.StartInGameChecking(ClientNumber, procedure(const ErrorFiles: TStringList)
      begin
        ErrorFiles.SaveToFile('ErrorFiles.txt');
        MessageBoxTimeout(
                           0,
                           PChar(
                                  'Обнаружено изменение критичных файлов!' + #13#10 +
                                  'Список файлов сохранён в ErrorFiles.txt'
                                 ),
                           'Обнаружено изменение клиента!',
                           MB_ICONERROR,
                           0,
                           5000
                          );
        ExitProcess(0);
      end);

      FLauncherAPI.ValidateClient(ClientNumber, True, procedure(ClientNumber: Integer; ClientValidationStatus, JavaValidationStatus: VALIDATION_STATUS)
      begin
        if (ClientValidationStatus <> VALIDATION_STATUS_SUCCESS) {$IFDEF DOUBLE_CHECK_JAVA} or (JavaValidationStatus <> VALIDATION_STATUS_SUCCESS) {$ENDIF} then
        begin
          MessageBoxTimeout(0, 'Обнаружено изменение клиента!', 'Внимание!', MB_ICONERROR, 0, 5000);
          ExitProcess(0);
        end;
      end);
    {$ENDIF}
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.ValidateClient(ClientNumber: Integer;
  PlayAfterValidation: Boolean);
begin
  if (ClientNumber < 0) or (FLauncherAPI.Clients.Count = 0) or (ClientNumber > FLauncherAPI.Clients.Count - 1) then
  begin
    ShowErrorMessage('Неверный выбранный клиент!');
    PlayButton.Enabled := True;
    Exit;
  end;

  if FLauncherAPI.Clients.ClientsArray[ClientNumber].GetValidationStatus then
  begin
    if not PlayAfterValidation then ShowErrorMessage('Клиент уже обновляется! Дождитесь завершения и попробуйте снова!');
    Exit;
  end;

  FServerPanels[ClientNumber].Content.InfoLabel.Text := 'Получаем список файлов...';
  FLauncherAPI.GetValidFilesList(ClientNumber, procedure(ClientNumber: Integer; QueryStatus: QUERY_STATUS)
  begin
    if QueryStatus.StatusCode <> QUERY_STATUS_SUCCESS then
    begin
      ShowErrorMessage('[Код ошибки ' + IntToStr(Integer(QueryStatus.StatusCode)) + '] ' + QueryStatus.StatusString);
      FServerPanels[ClientNumber].Content.InfoLabel.Text := FLauncherAPI.Clients.ClientsArray[ClientNumber].ServerInfo.Info;
      PlayButton.Enabled := True;
      Exit;
    end;

    FServerPanels[ClientNumber].Content.InfoLabel.Text := 'Проверяем файлы...';
    FLauncherAPI.ValidateClient(ClientNumber, True, procedure(ClientNumber: Integer; ClientValidationStatus, JavaValidationStatus: VALIDATION_STATUS)
    begin
      if (ClientValidationStatus = VALIDATION_STATUS_SUCCESS) and (JavaValidationStatus = VALIDATION_STATUS_SUCCESS) then
      begin
        FServerPanels[ClientNumber].Content.InfoLabel.Text := FLauncherAPI.Clients.ClientsArray[ClientNumber].ServerInfo.Info;
        if PlayAfterValidation then LaunchClient(ClientNumber);
        Exit;
      end;

      if (ClientValidationStatus = VALIDATION_STATUS_DELETION_ERROR) or (JavaValidationStatus = VALIDATION_STATUS_DELETION_ERROR) then
      begin
        ShowErrorMessage(
                          'Не получилось удалить следующие файлы:' + #13#10 +
                          FLauncherAPI.Clients.ClientsArray[ClientNumber].FilesValidator.ErrorFiles.Text + #13#10 +
                          FLauncherAPI.JavaInfo.FilesValidator.ErrorFiles.Text + #13#10 +
                          'Возможно лаунчер уже был запущен, попробуйте завершить его через Диспетчер Задач.'
                         );
        FServerPanels[ClientNumber].Content.InfoLabel.Text := FLauncherAPI.Clients.ClientsArray[ClientNumber].ServerInfo.Info;
        PlayButton.Enabled := True;
        Exit;
      end;

      if (ClientValidationStatus = VALIDATION_STATUS_NEED_UPDATE) or (JavaValidationStatus = VALIDATION_STATUS_NEED_UPDATE) then
      begin
        FServerPanels[ClientNumber].Content.InfoLabel.Text := 'Начинаем загрузку...';
        FServerPanels[ClientNumber].ShowDownloadPanel;
        FLauncherAPI.UpdateClient(ClientNumber, {$IFDEF SINGLE_THREAD_DOWNLOADING}False{$ELSE}True{$ENDIF}, OnDownload);
      end;
    end);
  end);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                             Запуск игры
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.AttemptToLaunchClient;
var
  I: Integer;
  CurrentRAM, Delta: Int64;
  MemoryStatusEx: _MEMORYSTATUSEX;
begin
  // Проверяем валидность номера клиента:
  if (FLauncherAPI.Clients.Count = 0) or (FSelectedClientNumber < 0) or (FSelectedClientNumber >= FLauncherAPI.Clients.Count) then
  begin
    ShowErrorMessage('Клиент не выбран!');
    Exit;
  end;

  if Length(JavaVersionEdit.Text) = 0 then
  begin
    ShowErrorMessage('Введите корректную версию Java!');
    Exit;
  end;

  if Length(RAMEdit.Text) = 0 then
  begin
    ShowErrorMessage('Введите корректную величину RAM!');
    Exit;
  end;

  MemoryStatusEx.dwLength := SizeOf(MemoryStatusEx);
  GlobalMemoryStatusEx(MemoryStatusEx);
  CurrentRAM := StrToInt(RAMEdit.Text);

  if CurrentRAM < 512 then
  begin
    ShowErrorMessage('Установленного количества оперативной памяти может быть недостаточно для запуска Minecraft. Рекомендуется установить в настройках как минимум 512 мегабайт RAM.');
  end;

  Delta := (Int64(MemoryStatusEx.ullAvailPhys) div 1048576) - CurrentRAM;
  if Delta < 128 then
  begin
    ShowErrorMessage('Недостаточно памяти для запуска игры!' + #13#10 + 'Совет 1: Попробуйте закрыть Google Chrome, Skype, Acrobat Reader, а так же другие неиспользуемые программы.' + #13#10 + 'Совет 2: Уменьшите количество памяти в настройках.' + #13#10 + 'Совет 3: Завершите через Диспетчер Задач зависший процесс игры.');
    Exit;
  end;

  // Делаем все панельки, кроме выбранной, неактивными:
  ScrollBox.BeginUpdate;
  FSelectedToPlayClientNumber := FSelectedClientNumber;
  for I := 0 to FLauncherAPI.Clients.Count - 1 do
  begin
    if I <> FSelectedToPlayClientNumber then
    begin
      FServerPanels[I].SetDisabledView;
      FLauncherAPI.Clients.ClientsArray[I].MultiLoader.Cancel; // Останавливаем все загрузки
    end;
  end;
  FServerPanels[FSelectedToPlayClientNumber].SetSelectedView;
  ScrollBox.EndUpdate;
  ScrollBox.Repaint;

  PlayButton.Enabled := False;
  WorkingFolderEdit.Enabled := False;

  // Запускаем проверку клиента:
  ValidateClient(FSelectedClientNumber, True);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.PlayButtonClick(Sender: TObject);
begin
  AttemptToLaunchClient;
end;



//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                        Обработка событий клиента
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

{$IFDEF USE_MONITORING}
procedure TMainForm.OnMonitoring(ServerNumber: Integer;
  const MonitoringInfo: TMonitoringInfo);
var
  ServerPanel: TServerPanel;
begin
  ServerPanel := FServerPanels[ServerNumber];
  if MonitoringInfo.IsActive then
  begin
    ServerPanel.Content.MonitoringInfo.Text := '(' + MonitoringInfo.CurrentPlayers + '/' + MonitoringInfo.MaxPlayers + ')';
    {$IFDEF FLASHING_LAMP}ServerPanel.BlinkGood;{$ELSE}ServerPanel.SetGoodLight;{$ENDIF}
  end
  else
  begin
    ServerPanel.Content.MonitoringInfo.Text := '';
    {$IFDEF FLASHING_LAMP}ServerPanel.BlinkBad;{$ELSE}ServerPanel.SetBadLight;{$ENDIF}
  end;
end;
{$ENDIF}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.OnDownload(ClientNumber: Integer;
  const DownloadInfo: TMultiLoaderDownloadInfo);

  function GetSizeString(BytesCount: Integer): string; inline;
  var
    Kilobytes: Integer;
  begin
    Kilobytes := BytesCount div 1024;
    if Kilobytes > 1024 then Result := FormatFloat('0.0', Kilobytes / 1024) + ' МБ' else Result := IntToStr(Kilobytes) + ' КБ';
  end;

  function GetSpeedString(const BytesPerSec: Single): string; inline;
  var
    KbPerSec: Single;
  begin
    KbPerSec := BytesPerSec / 1024;
    if KbPerSec > 1024 then Result := FormatFloat('0.0', KbPerSec / 1024) + ' МБ/с.' else Result := FormatFloat('0.0', KbPerSec) + ' КБ/с.';
  end;

var
  ServerPanel: TServerPanel;
  Time: Single;
  SpeedStr, TimeStr: string;
begin
  if FIsDrag then Exit;

  ServerPanel := FServerPanels[ClientNumber];

  if DownloadInfo.SummaryDownloadInfo.IsFinished then
  begin
    ServerPanel.Content.ServerPanel.BeginUpdate;
    ServerPanel.HideDownloadPanel;
    ServerPanel.EnableDownloadButtons;
    ServerPanel.Content.ProgressBar.Value := 0;
    ServerPanel.Content.NameLabel.Text := FLauncherAPI.Clients.ClientsArray[ClientNumber].ServerInfo.Name;
    ServerPanel.Content.InfoLabel.Text := FLauncherAPI.Clients.ClientsArray[ClientNumber].ServerInfo.Info;
    ServerPanel.Content.ServerPanel.EndUpdate;
    ServerPanel.Content.ServerPanel.Repaint;

    if not DownloadInfo.SummaryDownloadInfo.IsCancelled then
      ValidateClient(ClientNumber, ClientNumber = FSelectedToPlayClientNumber)
    else if ClientNumber = FSelectedToPlayClientNumber then
      PlayButton.Enabled := True;
  end
  else
  begin
    if not DownloadInfo.SummaryDownloadInfo.IsCancelled and not DownloadInfo.SummaryDownloadInfo.IsPaused then
    begin
      Time := DownloadInfo.SummaryDownloadInfo.RemainingTime;
      SpeedStr := GetSpeedString(DownloadInfo.SummaryDownloadInfo.Speed);

      TimeStr := FormatFloat('0.0', Time) + ' сек.';

      ServerPanel.Content.ServerPanel.BeginUpdate;
      ServerPanel.Content.ProgressBar.Value := 100 * DownloadInfo.SummaryDownloadInfo.Downloaded / DownloadInfo.SummaryDownloadInfo.FullSize;
      ServerPanel.Content.NameLabel.Text := FLauncherAPI.Clients.ClientsArray[ClientNumber].ServerInfo.Name + ' (' +
                                            DownloadInfo.SummaryDownloadInfo.FilesDownloaded.ToString + '/' +
                                            DownloadInfo.SummaryDownloadInfo.FilesCount.ToString + ')';
      ServerPanel.Content.InfoLabel.Text := SpeedStr + ', ' + TimeStr;
      ServerPanel.Content.ServerPanel.EndUpdate;
    end;
  end;
end;




//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                Обработка всплывающего меню списка серверов
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.ServersPopupMenuPopup(Sender: TObject);
begin
  if PlayButton.Enabled then
  begin
    SelectClient(TControl(Sender).Tag);
    FIsPopup := True;
  end else
    begin
      // Если процесс запуска игры уже начат, то запрещаем всплывать PopupMenu
      FIsPopup := False;
      Abort;
    end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.AddonItemClick(Sender: TObject);
var
  Client: TMinecraftLauncher;
  AddonId: string;
  ImgSize: TSizeF;
begin
  Client := FLauncherAPI.Clients.ClientsArray[TControl(Sender).Tag];
  AddonId := TControl(Sender).TagString;
  ImgSize := TSizeF.Create(16,16);
  With (Sender as TMenuItem) do
  begin
  IsChecked := not IsChecked;
  if IsChecked then
    Bitmap := ServersPopupImageList.Bitmap(ImgSize, 1) else
    Bitmap := ServersPopupImageList.Bitmap(ImgSize, 0);
  SaveBooleanToRegistry(RegistryPath, 'addon_' + AddonId, IsChecked);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.OpenFolderItemClick(Sender: TObject);
var
  Client: TMinecraftLauncher;
  Path: string;
begin
  Client := FLauncherAPI.Clients.ClientsArray[TControl(Sender).Tag];
  Path := FLauncherAPI.LocalWorkingFolder + '\' + Client.ServerInfo.ClientFolder;
  CreatePath(Path);
  ShellExecute(GetFmxWND(Handle), nil, PChar(Path), nil, nil, SW_SHOWNORMAL);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.UpdateClientItemClick(Sender: TObject);
begin
  ValidateClient(TControl(Sender).Tag, False);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeleteClientItemClick(Sender: TObject);
var
  Client: TMinecraftLauncher;
  Path: string;
begin
  Client := FLauncherAPI.Clients.ClientsArray[TControl(Sender).Tag];
  Path := FLauncherAPI.LocalWorkingFolder + '\' + Client.ServerInfo.ClientFolder;
  if MessageBox(GetFmxWND(Handle), 'Вы действительно хотите стереть все файлы из папки с клиентом?', 'Внимание!', MB_ICONQUESTION + MB_YESNO) = ID_YES then
  begin
    DeleteDirectory(Path + '\*');
  end;
end;






//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                    Обработка всплывающего меню скина
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.SkinPopupMenuPopup(Sender: TObject);
begin
  if PlayButton.Enabled then
  begin
    FIsPopUp := True;
  end else
    begin
      // Если процесс запуска игры уже начат, то запрещаем всплывать PopupMenu
      FIsPopup := False;
      Abort;
    end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DrawCloakItemClick(Sender: TObject);
begin
  CloakContainer.Visible := not CloakContainer.Visible;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DrawHelmetItemClick(Sender: TObject);
begin
  HelmetContainer.Visible := not HelmetContainer.Visible;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DrawWireframeItemClick(Sender: TObject);
begin
  FDrawWireframe := not FDrawWireframe;
  Viewport3D.Repaint;
end;



//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                      Установка/удаление скинов и плащей
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.CheckSkinSystemErrors(Status: SKIN_SYSTEM_STATUS;
  ImageType: IMAGE_TYPE; const ErrorReason: string);
begin
  case Status of
    SKIN_SYSTEM_FILE_NOT_EXISTS:
      case ImageType of
        IMAGE_SKIN  : ShowErrorMessage('Скин ещё не установлен!');
        IMAGE_CLOAK : ShowErrorMessage('Плащ ещё не установлен!');
      end;
    SKIN_SYSTEM_NOT_PNG                 : ShowErrorMessage('Файл - не PNG!');
    SKIN_SYSTEM_CONNECTION_ERROR        : ShowErrorMessage('Не удалось подключиться к серверу!' + #13#10 + 'Попробуйте снова через несколько минут.');
    SKIN_SYSTEM_UNKNOWN_ERROR           : ShowErrorMessage(ErrorReason);
    SKIN_SYSTEM_UNKNOWN_RESPONSE_FORMAT : ShowErrorMessage('Неизвестный формат ответа!');
  end;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.SetupSkinItemClick(Sender: TObject);
var
  SkinPath: string;
  Status: SKIN_SYSTEM_STATUS;
begin
  if not ShowOpenDialog(SkinPath, '*.png|*.png') then Exit;

  Status := FLauncherAPI.SetupSkin(FLauncherAPI.UserInfo.UserLogonData.Login, PasswordEdit.Text, SkinPath);
  if Status <> SKIN_SYSTEM_SUCCESS then
  begin
    CheckSkinSystemErrors(Status, IMAGE_SKIN, FLauncherAPI.SkinSystem.ErrorReason);
    Exit;
  end;

  FLauncherAPI.UserInfo.SkinBitmap.LoadFromFile(SkinPath);
  DrawSkin(FLauncherAPI.UserInfo.SkinBitmap);
  ShowSuccessMessage('Скин успешно установлен!');
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DownloadSkinItemClick(Sender: TObject);
var
  SkinPath: string;
  Status: SKIN_SYSTEM_STATUS;
begin
  if not ShowSaveDialog(SkinPath, '*.png|*.png', FLauncherAPI.UserInfo.UserLogonData.Login + '.png') then Exit;

  Status := FLauncherAPI.DownloadSkin(FLauncherAPI.UserInfo.UserLogonData.Login, PasswordEdit.Text, SkinPath);
  if Status <> SKIN_SYSTEM_SUCCESS then
  begin
    CheckSkinSystemErrors(Status, IMAGE_SKIN, FLauncherAPI.SkinSystem.ErrorReason);
    Exit;
  end;

  ShowSuccessMessage('Скин сохранён в папку: ' + SkinPath);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeletSkinItemClick(Sender: TObject);
var
  Status: SKIN_SYSTEM_STATUS;
begin
  Status := FLauncherAPI.DeleteSkin(FLauncherAPI.UserInfo.UserLogonData.Login, PasswordEdit.Text);

  if Status <> SKIN_SYSTEM_SUCCESS then
  begin
    CheckSkinSystemErrors(Status, IMAGE_SKIN, FLauncherAPI.SkinSystem.ErrorReason);
    Exit;
  end;

  DrawSkin(FLauncherAPI.UserInfo.SkinBitmap);
  ShowSuccessMessage('Скин удалён!');
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.SetupCloakItemClick(Sender: TObject);
var
  CloakPath: string;
  Status: SKIN_SYSTEM_STATUS;
begin
  if not ShowOpenDialog(CloakPath) then Exit;

  Status := FLauncherAPI.SetupCloak(FLauncherAPI.UserInfo.UserLogonData.Login, PasswordEdit.Text, CloakPath);
  if Status <> SKIN_SYSTEM_SUCCESS then
  begin
    CheckSkinSystemErrors(Status, IMAGE_CLOAK, FLauncherAPI.SkinSystem.ErrorReason);
    Exit;
  end;

  DrawCloak(FLauncherAPI.UserInfo.CloakBitmap);
  ShowSuccessMessage('Плащ успешно установлен!');
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DownloadCloakItemClick(Sender: TObject);
var
  CloakPath: string;
  Status: SKIN_SYSTEM_STATUS;
begin
  if not ShowSaveDialog(CloakPath, '*.png|*.png', FLauncherAPI.UserInfo.UserLogonData.Login + '_cloak.png') then Exit;

  Status := FLauncherAPI.DownloadCloak(FLauncherAPI.UserInfo.UserLogonData.Login, PasswordEdit.Text, CloakPath);
  if Status <> SKIN_SYSTEM_SUCCESS then
  begin
    CheckSkinSystemErrors(Status, IMAGE_CLOAK, FLauncherAPI.SkinSystem.ErrorReason);
    Exit;
  end;

  ShowSuccessMessage('Плащ сохранён в папку: ' + CloakPath);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DeleteCloakItemClick(Sender: TObject);
var
  Status: SKIN_SYSTEM_STATUS;
begin
  Status := FLauncherAPI.DeleteCloak(FLauncherAPI.UserInfo.UserLogonData.Login, PasswordEdit.Text);

  if Status <> SKIN_SYSTEM_SUCCESS then
  begin
    CheckSkinSystemErrors(Status, IMAGE_CLOAK, FLauncherAPI.SkinSystem.ErrorReason);
    Exit;
  end;

  DrawCloak(FLauncherAPI.UserInfo.CloakBitmap);
  ShowSuccessMessage('Плащ удалён!');
end;



//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//                                3D-скины
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TMainForm.CreateMaterialSources;
var
  Component: TComponent;
  Plane: TPlane;
begin
  Viewport3D.BeginUpdate;
  for Component in MainForm do if Component is TPlane then
  begin
    Plane := TPlane(Component);
    Plane.MaterialSource := TTextureMaterialSource.Create(ModelContainer);
    TTextureMaterialSource(Plane.MaterialSource).Texture.Clear($00000000);
    Plane.OnRender := OnPlaneRender;
  end;
  Viewport3D.EndUpdate;
  Viewport3D.Repaint;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DestroyMaterialSources;
var
  Component: TComponent;
  Plane: TPlane;
begin
  Viewport3D.BeginUpdate;
  for Component in MainForm do if Component is TPlane then
  begin
    Plane := TPlane(Component);
    Plane.MaterialSource.Free;
  end;
  Viewport3D.EndUpdate;
  Viewport3D.Repaint;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.Viewport3DMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  ScrollBox.BeginUpdate;
  if Button = TMouseButton.mbMiddle then
  begin
    ModelContainer.ResetRotationAngle;
    ModelContainer.RotationAngle.Y  := 25;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.Viewport3DMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  ScrollBox.EndUpdate;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.Viewport3DMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
var
  DeltaX, DeltaY: Single;
begin
  if ssLeft in Shift then
  begin
    if FIsPopup then
    begin
      FLastPoint := PointF(X, Y);
      FIsPopup := False;
      Exit;
    end;

    DeltaX := FLastPoint.X - X;
    DeltaY := FLastPoint.Y - Y;

    Viewport3D.BeginUpdate;
    with ModelContainer do
    begin
      // Поворачиваем скин:
      RotationAngle.Y := RotationAngle.Y + DeltaX;
      RotationAngle.X := RotationAngle.X - DeltaY * Cos((Pi * RotationAngle.Y) / 180);
      RotationAngle.Z := RotationAngle.Z - DeltaY * Sin((Pi * RotationAngle.Y) / 180);
    end;
{
    with CameraContainer do
    begin
      // Поворачиваем камеру:
      RotationAngle.Y := RotationAngle.Y + DeltaX;
      RotationAngle.X := RotationAngle.X - DeltaY * Cos((Pi * RotationAngle.Y) / 180);
      RotationAngle.Z := RotationAngle.Z - DeltaY * Sin((Pi * RotationAngle.Y) / 180);
    end;
}
    Viewport3D.EndUpdate;
    Viewport3D.Repaint;
  end;
  FLastPoint := PointF(X, Y);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.Viewport3DMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
  function Sign(Value: Single): Integer; inline;
  begin
    if Value = 0 then Exit(0);
    if Value > 0 then Exit(1) else Exit(-1);
  end;
var
  Direction: Integer;
begin
  Direction := Sign(WheelDelta);

  case Direction of
    1  : if Camera.Position.Z < -3 then Camera.Position.Z := Camera.Position.Z + Direction;
    -1 : if Camera.Position.Z > -16 then Camera.Position.Z := Camera.Position.Z + Direction;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.OnPlaneRender(Sender: TObject; Context: TContext3D);
const
  WireframeColor = $FF00FFFF;
  WireframeOpacity = 0.7;
  DiagonalLineColor = $FFFFFF00;
  DiagonalLineOpacity = 0.6;
begin
  if FDrawWireframe then
  begin
    Context.BeginScene;
    Context.DrawLine(TPoint3D.Create(-0.5, -0.5, 0), TPoint3D.Create(-0.5, 0.5 , 0), WireframeOpacity, WireframeColor);
    Context.DrawLine(TPoint3D.Create(-0.5, 0.5 , 0), TPoint3D.Create(0.5 , 0.5 , 0), WireframeOpacity, WireframeColor);
    Context.DrawLine(TPoint3D.Create(0.5 , 0.5 , 0), TPoint3D.Create(0.5 , -0.5, 0), WireframeOpacity, WireframeColor);
    Context.DrawLine(TPoint3D.Create(0.5 , -0.5, 0), TPoint3D.Create(-0.5, -0.5, 0), WireframeOpacity, WireframeColor);
    Context.DrawLine(TPoint3D.Create(-0.5, -0.5, 0), TPoint3D.Create(0.5 , 0.5 , 0), DiagonalLineOpacity, DiagonalLineColor);
    Context.EndScene;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Скопировать часть битмапа в другой битмап:
procedure CopyBitmapToBitmap(
                              const SrcBitmap    : FMX.Graphics.TBitmap; // Из какого битмапа копируем
                              const DestBitmap   : FMX.Graphics.TBitmap; // В какой битмап копируем
                              const SrcRect      : TRectF;               // Какой прямоугольник
                              const DstRect      : TRectF;               // В какой прямоугольник
                              ScaleCoeff         : Single  = 1.0;        // Коэффициент масштабирования (DstRect * ScaleCoeff)
                              Opacity            : Single  = 1.0;        // Коэффициент прозрачности накладываемого изображения
                              FlushBeforeDrawing : Boolean = True;       // Очищать ли предыдущее содержимое
                              Interpolate        : Boolean = False       // Интерполировать ли при масштабировании
                             );

  function Max(const A, B: Single): Single; inline;
  begin
    if A > B then Result := A else Result := B;
  end;

begin
  if not Assigned(SrcBitmap) or not Assigned(DestBitmap) then Exit;

  DestBitmap.SetSize(Round(Max(DstRect.Left, DstRect.Right) * ScaleCoeff), Round(Max(DstRect.Top, DstRect.Bottom) * ScaleCoeff));
  DestBitmap.Canvas.BeginScene;
  if FlushBeforeDrawing then DestBitmap.Clear($00000000);
  DestBitmap.Canvas.DrawBitmap(
                                SrcBitmap,
                                SrcRect,
                                RectF(
                                       DstRect.Left,
                                       DstRect.Top,
                                       DstRect.Left + ((DstRect.Right - DstRect.Left) * ScaleCoeff),
                                       DstRect.Top  + ((DstRect.Bottom - DstRect.Top) * ScaleCoeff)
                                      ),
                                Opacity,
                                not Interpolate
                               );
  DestBitmap.Canvas.EndScene;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TMainForm.DrawSkin(const Bitmap: FMX.Graphics.TBitmap);
type
  TTextureInfo  = array of Integer;      // OffsetX, OffsetY, Width, Height
  TCubeTexture  = array of TTextureInfo; // Front, Back, Left, Right, Top, Bottom
  TSurfaceArray = array of ^TPlane;

// Индексы элементов в массивах:
const
  iOffsetX = 0;
  iOffsetY = 1;
  iWidth   = 2;
  iHeight  = 3;

  iFront  = 0;
  iBack   = 1;
  iLeft   = 2;
  iRight  = 3;
  iTop    = 4;
  iBottom = 5;

  iHead     = 0;
  iTorso    = 1;
  iLeftArm  = 2;
  iRightArm = 3;
  iLeftLeg  = 4;
  iRightLeg = 5;
  iHelmet   = 6;

const
  HeadTexture : TCubeTexture = [// X  Y  W  H
                                 [8 , 8, 8, 8], // Front
                                 [24, 8, 8, 8], // Back
                                 [16, 8, 8, 8], // Left
                                 [0 , 8, 8, 8], // Right
                                 [8 , 0, 8, 8], // Top
                                 [16, 0, 8, 8]  // Bottom
                                ];

  TorsoTexture : TCubeTexture = [
                                  [20, 20, 8, 12], // Front
                                  [32, 20, 8, 12], // Back
                                  [28, 20, 4, 12], // Left
                                  [16, 20, 4, 12], // Right
                                  [20, 16, 8, 4 ], // Top
                                  [28, 16, 8, 4 ]  // Bottom
                                 ];

  LeftArmTexture : TCubeTexture = [
                                    [44, 20, 4, 12], // Front
                                    [52, 20, 4, 12], // Back
                                    [48, 20, 4, 12], // Left
                                    [40, 20, 4, 12], // Right
                                    [44, 16, 4, 4 ], // Top
                                    [48, 16, 4, 4 ]  // Bottom
                                   ];

  RightArmTexture : TCubeTexture = [
                                     [44, 20, 4, 12], // Front
                                     [52, 20, 4, 12], // Back
                                     [48, 20, 4, 12], // Left
                                     [40, 20, 4, 12], // Right
                                     [44, 16, 4, 4 ], // Top
                                     [48, 16, 4, 4 ]  // Bottom
                                    ];

  LeftLegTexture : TCubeTexture = [
                                    [4 , 20, 4, 12], // Front
                                    [12, 20, 4, 12], // Back
                                    [0 , 20, 4, 12], // Left
                                    [8 , 20, 4, 12], // Right
                                    [4 , 16, 4, 4 ], // Top
                                    [8 , 16, 4, 4 ]  // Bottom
                                   ];

  RightLegTexture : TCubeTexture = [
                                     [4 , 20, 4, 12], // Front
                                     [12, 20, 4, 12], // Back
                                     [0 , 20, 4, 12], // Left
                                     [8 , 20, 4, 12], // Right
                                     [4 , 16, 4, 4 ], // Top
                                     [8 , 16, 4, 4 ]  // Bottom
                                    ];

  HelmetTexture : TCubeTexture = [
                                   [40, 8, 8, 8], // Front
                                   [56, 8, 8, 8], // Back
                                   [48, 8, 8, 8], // Left
                                   [32, 8, 8, 8], // Right
                                   [40, 0, 8, 8], // Top
                                   [48, 0, 8, 8]  // Bottom
                                  ];

const
  ScaleCoeff: Single = 10.0;

var
  // Список поверхностей каждой части модели:
  HeadPlanes     : TSurfaceArray;
  TorsoPlanes    : TSurfaceArray;
  LeftArmPlanes  : TSurfaceArray;
  RightArmPlanes : TSurfaceArray;
  LeftLegPlanes  : TSurfaceArray;
  RightLegPlanes : TSurfaceArray;
  HelmetPlanes   : TSurfaceArray;

  // Список частей модели:
  ModelParts: array of ^TSurfaceArray;

  // Список текстур каждой части модели:
  DefaultTextures: array of ^TCubeTexture;
  ObjectTextures: array of TCubeTexture;

  // Коэффициент масштабирования координат для HD-скинов:
  CoordScaleCoeffX, CoordScaleCoeffY: Integer;

  // I - счётчик по частям модели, J - счётчик по поверхностям:
  I, J: LongWord;

begin
  if not Assigned(Bitmap) then Exit;

  Viewport3D.BeginUpdate;

  // Получаем коэффициенты масштабирования координат:
  if Bitmap.Width = Bitmap.Height then
  begin
    // Новые скины, с версии Minecraft 1.8
    CoordScaleCoeffX := Bitmap.Width div 64;
    CoordScaleCoeffY := Bitmap.Height div 64;
  end else
    begin
      // Старые скины
      CoordScaleCoeffX := Bitmap.Width div 64;
      CoordScaleCoeffY := Bitmap.Height div 32;
    end;

  // Составляем массив из групп текстур для каждой части модели:
  DefaultTextures := [@HeadTexture, @TorsoTexture, @LeftArmTexture, @RightArmTexture, @LeftLegTexture, @RightLegTexture, @HelmetTexture];

  // Создаём массив отмасштабированных координат:
  SetLength(ObjectTextures, Length(DefaultTextures));
  for I := 0 to Length(ObjectTextures) - 1 do
  begin
    SetLength(ObjectTextures[I], Length(DefaultTextures[I]^));
    for J := 0 to Length(ObjectTextures[I]) - 1 do
    begin
      SetLength(ObjectTextures[I][J], 4);
      ObjectTextures[I][J][0] := DefaultTextures[I]^[J][0] * CoordScaleCoeffX;
      ObjectTextures[I][J][1] := DefaultTextures[I]^[J][1] * CoordScaleCoeffY;
      ObjectTextures[I][J][2] := DefaultTextures[I]^[J][2] * CoordScaleCoeffX;
      ObjectTextures[I][J][3] := DefaultTextures[I]^[J][3] * CoordScaleCoeffY;
    end;
  end;

  // Составляем список поверхностей:
  HeadPlanes     := [@HeadFront    , @HeadBack    , @HeadLeft     , @HeadRight    , @HeadTop    , @HeadBottom    ];
  TorsoPlanes    := [@TorsoFront   , @TorsoBack   , @TorsoLeft    , @TorsoRight   , @TorsoTop   , @TorsoBottom   ];
  LeftArmPlanes  := [@LeftArmFront , @LeftArmBack , @LeftArmRight , @LeftArmLeft  , @LeftArmTop , @LeftArmBottom ];
  RightArmPlanes := [@RightArmFront, @RightArmBack, @RightArmLeft , @RightArmRight, @RightArmTop, @RightArmBottom];
  LeftLegPlanes  := [@LeftLegFront , @LeftLegBack , @LeftLegLeft  , @LeftLegRight , @LeftLegTop , @LeftLegBottom ];
  RightLegPlanes := [@RightLegFront, @RightLegBack, @RightLegRight, @RightLegLeft , @RightLegTop, @RightLegBottom];
  HelmetPlanes   := [@HelmetFront  , @HelmetBack  , @HelmetLeft   , @HelmetRight  , @HelmetTop  , @HelmetBottom  ];

  // Составляем список частей модели:
  ModelParts := [@HeadPlanes, @TorsoPlanes, @LeftArmPlanes, @RightArmPlanes, @LeftLegPlanes, @RightLegPlanes, @HelmetPlanes];

  // Проходимся по каждой части модели (голова, корпус, ...):
  for I := 0 to High(ModelParts) do
  begin
    // Проходимся по каждой поверхности модели:
    for J := 0 to High(ModelParts[I]^) do
    begin
      // Рисуем текстуру на каждой поверхности:
      with ModelParts[I]^[J]^ do
      begin
        ModelParts[I]^[J]^.BeginUpdate;

        CopyBitmapToBitmap(
                            Bitmap,
                            TTextureMaterialSource(MaterialSource).Texture,
                            RectF(
                                   ObjectTextures[I][J][iOffsetX],
                                   ObjectTextures[I][J][iOffsetY],
                                   ObjectTextures[I][J][iOffsetX] + ObjectTextures[I][J][iWidth],
                                   ObjectTextures[I][J][iOffsetY] + ObjectTextures[I][J][iHeight]
                                  ),
                            RectF(0, 0, ObjectTextures[I][J][iWidth], ObjectTextures[I][J][iHeight]),
                            ScaleCoeff / ((CoordScaleCoeffX + CoordScaleCoeffY) div 2)
                           );

        // Инвертируем текстуры для симметрии:
        if (I in [iLeftArm, iLeftLeg]) then
          TTextureMaterialSource(MaterialSource).Texture.FlipHorizontal;

        ModelParts[I]^[J]^.EndUpdate;
      end;
    end;
  end;

  // Освобождаем массив отмасштабированных координат:
  for I := 0 to Length(ObjectTextures) - 1 do
  begin
    for J := 0 to Length(ObjectTextures[I]) - 1 do
      SetLength(ObjectTextures[I][J], 0);
    SetLength(ObjectTextures[I], 0);
  end;
  SetLength(ObjectTextures, 0);

  Viewport3D.EndUpdate;
  Viewport3D.RecalcOpacity;
  Viewport3D.Repaint;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure DbgPrint(const Str: string);
begin
  OutputDebugString(PChar(Str));
end;

procedure TMainForm.DrawCloak(const Bitmap: FMX.Graphics.TBitmap);
type
  TTextureInfo  = array of Integer;      // OffsetX, OffsetY, Width, Height
  TCubeTexture  = array of TTextureInfo; // Front, Back, Left, Right, Top, Bottom
  TSurfaceArray = array of ^TPlane;

// Индексы элементов в массивах:
const
  iOffsetX = 0;
  iOffsetY = 1;
  iWidth   = 2;
  iHeight  = 3;

  iFront  = 0;
  iBack   = 1;
  iLeft   = 2;
  iRight  = 3;
  iTop    = 4;
  iBottom = 5;

  iCloak = 0;

const
  CloakTexture : TCubeTexture = [// X  Y  W  H
                                  [1 , 1, 10, 16], // Front
                                  [12, 1, 10, 16], // Back
                                  [11, 1, 1 , 16], // Left
                                  [0 , 1, 1 , 16], // Right
                                  [1 , 0, 10, 1],  // Top
                                  [11, 0, 10, 1]   // Bottom
                                 ];
const
  ScaleCoeff: Single = 10.0;

var
  // Список поверхностей каждой части модели:
  CloakPlanes: TSurfaceArray;

  // Список из текстур каждой поверхности:
  ObjectTexture: TCubeTexture;

  // Коэффициент масштабирования координат для HD-скинов:
  CoordScaleCoeffX, CoordScaleCoeffY: Integer;

  // I - счётчик по поверхностям:
  I: LongWord;

begin
  if not Assigned(Bitmap) then Exit;

  Viewport3D.BeginUpdate;

  // Получаем коэффициенты масштабирования координат:
  if Bitmap.Width = Bitmap.Height then
  begin
    // Новые скины, с версии Minecraft 1.8
    CoordScaleCoeffX := Bitmap.Width div 64;
    CoordScaleCoeffY := Bitmap.Height div 64;
  end else
    begin
      // Старые скины
      CoordScaleCoeffX := Bitmap.Width div 64;
      CoordScaleCoeffY := Bitmap.Height div 32;
    end;

  // Создаём массив отмасштабированных координат:
  SetLength(ObjectTexture, Length(CloakTexture));
  for I := 0 to Length(ObjectTexture) - 1 do
  begin
    SetLength(ObjectTexture[I], 4);
    ObjectTexture[I][0] := CloakTexture[I][0] * CoordScaleCoeffX;
    ObjectTexture[I][1] := CloakTexture[I][1] * CoordScaleCoeffY;
    ObjectTexture[I][2] := CloakTexture[I][2] * CoordScaleCoeffX;
    ObjectTexture[I][3] := CloakTexture[I][3] * CoordScaleCoeffY;
  end;

  // Составляем список поверхностей:
  CloakPlanes := [@CloakFront, @CloakBack, @CloakLeft, @CloakRight, @CloakTop, @CloakBottom];

  // Проходимся по поверхностям плаща:
  for I := 0 to Length(CloakPlanes) - 1 do
  begin
    // Рисуем текстуру на каждой поверхности:
    with CloakPlanes[I]^ do
    begin
      BeginUpdate;
      CopyBitmapToBitmap(
                          Bitmap,
                          TTextureMaterialSource(MaterialSource).Texture,
                          RectF(
                                 ObjectTexture[I][iOffsetX],
                                 ObjectTexture[I][iOffsetY],
                                 ObjectTexture[I][iOffsetX] + ObjectTexture[I][iWidth],
                                 ObjectTexture[I][iOffsetY] + ObjectTexture[I][iHeight]
                                ),
                          RectF(0, 0, ObjectTexture[I][iWidth], ObjectTexture[I][iHeight]),
                          ScaleCoeff / ((CoordScaleCoeffX + CoordScaleCoeffY) div 2)
                         );

      EndUpdate;
    end;
  end;

  // Освобождаем массив отмасштабированных координат:
  for I := 0 to Length(ObjectTexture) - 1 do
  begin
    SetLength(ObjectTexture[I], 0);
  end;
  SetLength(ObjectTexture, 0);

  Viewport3D.EndUpdate;
  Viewport3D.RecalcOpacity;
  Viewport3D.Repaint;
end;


end.
