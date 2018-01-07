unit HWID;

interface

function GetHWID: string;
function GetComplexHwid: string;

implementation

uses
  Windows, SysUtils, Classes, CodepageAPI, StringsAPI, Main, cHash, uSMBIOS;


function GetHDDSerialNumber(PhysicalDriveNumber: Integer; out HDDSerialNumber: string): Boolean;

  function ShiftPtr(Ptr: Pointer; Offset: NativeInt): Pointer; inline;
  begin
    Result := Pointer(NativeInt(Ptr) + Offset);
  end;

type
  STORAGE_PROPERTY_QUERY = record
    PropertyId: DWORD;
    QueryType: DWORD;
    AdditionalParameters: array [0..1] of WORD;
  end;

  STORAGE_DEVICE_DESCRIPTOR = record
    Version: ULONG;
    Size: ULONG;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Boolean;
    CommandQueueing: Boolean;
    VendorIdOffset: ULONG;         // 0x0C Vendor ID
    ProductIdOffset: ULONG;        // 0x10 Product ID
    ProductRevisionOffset: ULONG;  // 0x15 Revision
    SerialNumberOffset: ULONG;     // 0x18 Serial Number
    STORAGE_BUS_TYPE: DWORD;
    RawPropertiesLength: ULONG;
    RawDeviceProperties: array [0..2048] of Byte;
  end;

  PCharArray = ^TCharArray;
  TCharArray = array [0..32767] of AnsiChar;

const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;

var
  DriveHandle: THandle;
  PropQuery: STORAGE_PROPERTY_QUERY;
  DeviceDescriptor: STORAGE_DEVICE_DESCRIPTOR;
  Status: LongBool;
  Returned: LongWord;
begin
  Result := False;

  DriveHandle := CreateFile (
                              PChar('\\.\PhysicalDrive' + IntToStr(PhysicalDriveNumber)),
                              GENERIC_READ,
                              FILE_SHARE_READ,
                              nil,
                              OPEN_EXISTING,
                              0,
                              0
                             );

  if DriveHandle = INVALID_HANDLE_VALUE then Exit;

  ZeroMemory(@PropQuery, SizeOf(PropQuery));
  Status := DeviceIoControl(
                             DriveHandle,
                             IOCTL_STORAGE_QUERY_PROPERTY,
                             @PropQuery,
                             SizeOf(PropQuery),
                             @DeviceDescriptor,
                             SizeOf(DeviceDescriptor),
                             Returned,
                             nil
                            );

  CloseHandle(DriveHandle);

  if not Status then Exit;

  HDDSerialNumber := Trim(AnsiToWide(PAnsiChar(ShiftPtr(@DeviceDescriptor, DeviceDescriptor.SerialNumberOffset))));
  Result := True;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function SanitizeString(s: string): string;
var
  i:integer;
  whitelist: set of char;
  temp: string;
begin
temp := '';

whitelist := ['A'..'Z','a'..'z','0'..'9',':'];

if length(s) > 0 then
  for i := 1 to length(s) do
    if s[i] in whitelist then
      temp := temp + s[i];

Result := AnsiUpperCase(temp);

end;


function GetComplexHWID(): string;
var
  Hwid: string;
  i:integer;
  SMBios : TSMBios;
  LBaseBoard : TBaseBoardInformation;
  LEnclosure : TEnclosureInformation;
  LProcessorInfo : TProcessorInformation;
  LSystem: TSystemInformation;
  UUID   : Array[0..31] of AnsiChar;
begin

SMBios:=TSMBios.Create;

hwid := '';

try
//Информация о материнской плате
if SMBios.HasBaseBoardInfo then
for i:=Low(SMBios.BaseBoardInfo) to High(SMBios.BaseBoardInfo) do
  begin
  LBaseBoard := SMBios.BaseBoardInfo[i];
  hwid := hwid + LBaseBoard.ManufacturerStr;
  hwid := hwid + LBaseBoard.ProductStr;
  hwid := hwid + LBaseBoard.VersionStr;
  hwid := hwid + LBaseBoard.SerialNumberStr;
  end;

//Общая информация об окружении
if SMBios.HasEnclosureInfo then
for i:=Low(SMBios.EnclosureInfo) to High(SMBios.EnclosureInfo) do
  begin
  LEnclosure := SMBios.EnclosureInfo[i];
  hwid := hwid + LEnclosure.ManufacturerStr;
  hwid := hwid + LEnclosure.VersionStr;
  hwid := hwid + LEnclosure.SerialNumberStr;
  end;

//Информация о процессоре
if SMBios.HasProcessorInfo then
for i:=Low(SMBios.ProcessorInfo) to High(SMBios.ProcessorInfo) do
  begin
  LProcessorInfo:=SMBios.ProcessorInfo[i];
  hwid := hwid + LProcessorInfo.SocketDesignationStr;
  hwid := hwid + Format('%x',[LProcessorInfo.RAWProcessorInformation^.ProcessorID]);
  end;

//Общая информация о системе
LSystem:=SMBios.SysInfo;
hwid := hwid + LSystem.ManufacturerStr;
hwid := hwid + LSystem.ProductNameStr;
hwid := hwid + LSystem.VersionStr;
hwid := hwid + LSystem.SerialNumberStr;
BinToHex(@LSystem.RAWSystemInformation.UUID,UUID,SizeOf(LSystem.RAWSystemInformation.UUID));
hwid := hwid + UUID;
if SMBios.SmbiosVersion>='2.4' then
  begin
  hwid := hwid + LSystem.SKUNumberStr;
  hwid := hwid + LSystem.FamilyStr;
  end;

finally
SMBios.Free;
end;

Result := MD5DigestToHex(CalcMD5(hwid));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetHWID: string;
var
  PhysicalDriveNumber: Integer;
  HDDSerialNumber: string;
begin
  // Получаем номер системного HDD:
  GetHDDSerialNumber(0, Result);

  // Получаем остальные серийники:
  PhysicalDriveNumber := 1;
  while GetHDDSerialNumber(PhysicalDriveNumber, HDDSerialNumber) do
  begin
    if Length(Result) = 0 then HDDSerialNumber := 'UNKNOWN';
    Result := Result + ':' + HDDSerialNumber;
    Inc(PhysicalDriveNumber);
  end;

  if Length(Result) = 0 then Result := 'UNKNOWN';

Result := Result + ':' + 'COM' + MainForm.ComplexHwid;
Result := SanitizeString(Result);
Result := Result + ':' + 'CHK' + MD5DigestToHex(CalcMD5(Result));
end;

end.

