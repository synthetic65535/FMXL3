unit Encryption;

interface

uses Windows, SysUtils, cHash, LauncherSettings, DECCipher, CRC, DECHash, DECData, DECUtil, DECFmt;

function GetEncryptionKey(): AnsiString;
function GetPasswordKey(): AnsiString;
function HexEncode(Input: AnsiString): AnsiString;

procedure EncryptRijndael(var Data: AnsiString; Password: AnsiString; ExpandedDataLength: Cardinal = 204); overload;
procedure DecryptRijndael(var Data: AnsiString; Password: AnsiString); overload;
procedure DecryptRijndael(Data: Pointer; var DataLength: LongWord; Password: AnsiString); overload;

implementation

// -----------------------------------------------------------------------------

function GetPasswordKey(): AnsiString; // Перемешать ключ шифрования для хранения пароля в реестре
begin
  // Чтобы затруднить злоумышленникам поиск пароля здесь с помощью
  // каких-нибудь манипуляций со строками нужно "перемешать" PasswordKey
  result := PasswordKey;
end;

// -----------------------------------------------------------------------------

function GetEncryptionKey(): AnsiString; // Перемешать ключ шифрования для передачи по сети
begin
  // Чтобы затруднить злоумышленникам поиск пароля здесь с помощью
  // каких-нибудь манипуляций со строками нужно "перемешать" EncryptionKey
  result := EncryptionKey;
end;

// -----------------------------------------------------------------------------

function HexEncode(Input: AnsiString): AnsiString;
var StrLen, I: Cardinal;
begin
StrLen := Length(Input);
Result := '';
if StrLen = 0 then Exit;
for I := 1 to StrLen do
  Result := Result + IntToHex(Byte(Input[i]), 2);
end;

// -----------------------------------------------------------------------------

function BinaryToInt(B: Binary): Cardinal;
begin
  Result := (Byte(B[1]) shl 24) + (Byte(B[2]) shl 16) + (Byte(B[3]) shl 8) + Byte(B[4]);
end;

// -----------------------------------------------------------------------------

function IntToBinary(I: Cardinal): Binary;
begin
  Result := AnsiChar(I shr 24) + AnsiChar(I shr 16) + AnsiChar(I shr 8) + AnsiChar(I);
end;

// -----------------------------------------------------------------------------

// Структура зашифрованной информации:
//   (salt)(iv)[(length)(data)(filler)(md5)]
//   salt, 16 байт - соль для генерации ключа шифрования по алгоритму PBKDF2.
//   iv, 16 байт - начальный вектор для алгоритма шифрования Rijndael.
//   length, 4 байта - размер полезных данных.
//   filler, от 0 байт - случайные байты, которые дополняют байты length+data до длины, кратной 16.
//   md5, 16 байт - хеш от data.
//   Всё, что в квадратных скобках - зашифровано.

procedure EncryptRijndael(var Data: AnsiString; Password: AnsiString; ExpandedDataLength: Cardinal = 204); overload;
var
  IV: Binary;
  Key: Binary;
  Salt: Binary;
  Checksum: Binary;
  DataLength: Cardinal;
  PreparedData: Binary;
  EncryptedData: Binary;
  PreparedDataLength: Cardinal;
begin
  with TCipher_Rijndael.Create, Context do
  try
    RandomSeed;
    Salt := RandomBinary(16);
    IV := RandomBinary(16);
    DataLength := Length(Data);
    Checksum := THash_MD5.CalcBinary(Data);
    PreparedData := IntToBinary(DataLength) + Data;
    if (ExpandedDataLength > DataLength) then
      PreparedData := PreparedData + RandomBinary(ExpandedDataLength - DataLength);
    PreparedDataLength := length(PreparedData);
    while ((PreparedDataLength mod 16) <> 0) do
    begin
      PreparedData := PreparedData + AnsiChar(Random($ff));
      Inc(PreparedDataLength);
    end;
    PreparedData := PreparedData + Checksum;
    PreparedDataLength := PreparedDataLength + 16;
    Key := THash_SHA1.PBKDF2(Password, Salt, KeySize, 1000, TFormat_Copy);
    Mode := cmCBCx;
    Init(Key, IV);
    SetLength(EncryptedData, PreparedDataLength);
    Encode(PreparedData[1], EncryptedData[1], PreparedDataLength);
    Data := Salt + IV + EncryptedData;
  finally
    Free;
    ProtectBinary(IV);
    ProtectBinary(Key);
    ProtectBinary(Salt);
    ProtectBinary(Checksum);
    ProtectBinary(PreparedData);
    ProtectBinary(EncryptedData);
  end;
end;

// -----------------------------------------------------------------------------

procedure DecryptRijndael(var Data: AnsiString; Password: AnsiString); overload;
var
  IV: Binary;
  Salt: Binary;
  Key: Binary;
  Checksum: Binary;
  DataLength: Cardinal;
  EncryptedData: Binary;
  DecryptedData: Binary;
  DataLengthBinary: Binary;
  ExtendedDataLength: Cardinal;
begin
  with TCipher_Rijndael.Create, Context do
  try
    if (Length(Data) < 64) then
    begin
      //raise Exception.Create(''Not enough data to decrypt');
      Data := '';
      Exit;
    end;
    Salt := System.Copy(Data, 1, 16);
    IV := System.Copy(Data, 17, 16);
    ExtendedDataLength := Length(Data) - 32;
    EncryptedData := System.Copy(Data, 33, ExtendedDataLength);
    Key := THash_SHA1.PBKDF2(Password, Salt, KeySize, 1000, TFormat_Copy);
    Mode := cmCBCx;
    Init(Key, IV);
    SetLength(DecryptedData, ExtendedDataLength);
    Decode(EncryptedData[1], DecryptedData[1], ExtendedDataLength);
    DataLengthBinary := System.Copy(DecryptedData, 1, 4);
    DataLength := BinaryToInt(DataLengthBinary);
    if (DataLength > ExtendedDataLength - 20) then
    begin
      //raise Exception.Create('DataLength is too big');
      Data := '';
      Exit;
    end;

    Data := System.Copy(DecryptedData, 5, DataLength);
    Checksum := System.Copy(DecryptedData, Length(DecryptedData) - 15, 16);
    if (Checksum <> THash_MD5.CalcBinary(Data)) then
    begin
      //raise Exception.Create('Data is not valid');
      Data := '';
      Exit;
    end;
  finally
    Free;
    ProtectBinary(IV);
    ProtectBinary(Salt);
    ProtectBinary(Key);
    ProtectBinary(EncryptedData);
    ProtectBinary(DecryptedData);
    ProtectBinary(DataLengthBinary);
  end;
end;

// -----------------------------------------------------------------------------

// DataLength при расшифровке уменьшится.
procedure DecryptRijndael(Data: Pointer; var DataLength: LongWord; Password: AnsiString); overload;
var
  TempData: AnsiString;
begin
if (DataLength = 0) then
  Exit;
try
  SetLength(TempData, DataLength);
  CopyMemory(@(TempData[1]), Data, DataLength);
  DecryptRijndael(TempData, Password);
  DataLength := Length(TempData);
  if DataLength <> 0 then
    CopyMemory(Data, @(TempData[1]), DataLength);
except
  DataLength := 0;
end;
end;

// -----------------------------------------------------------------------------

end.

