unit FilesValidation;

interface

uses
  Windows, SysUtils, Classes, ShlwAPI,
  System.JSON, System.Threading, Generics.Collections,
  ValidationTypes, FilesScanner, JSONUtils,
  FileAPI, FilesNotifier, CodepageAPI, StringsAPI,
  cHash, RegistryUtils, LauncherSettings;

type
  TCheckingsInfo  = TJSONArray;
  TValidFilesJSON = TJSONArray;
  TAddonsJSON  = TJSONArray;

  VALIDATION_STATUS = (
    VALIDATION_STATUS_SUCCESS,        // Все файлы прошли проверку
    VALIDATION_STATUS_DELETION_ERROR, // Не получилось удалить несоответствующий файл
    VALIDATION_STATUS_NEED_UPDATE     // Требуется обновление
  );

  TAddonInfo = class
      FId      : string;      // Идентификатор аддона
      FName    : string;      // Имя аддона
      FEnabled : Boolean;     // Включен ли аддон
      FFiles   : TStringList; // Файлы аддона
    public
      property Id  : string read FId write FId;
      property Name  : string read FName write FName;
      property Files  : TStringList read FFiles write FFiles;
      property Enabled : Boolean read FEnabled write FEnabled;
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      procedure Update; // Обновить состояние Enabled из реестра
  end;

  TCheckingsList = array of TFilesScannerStruct; // Список файлов и папок на проверку
  TAddonsList = array of TAddonInfo; // Список аддонов
  TOnFilesMismatching = reference to procedure(const ErrorFiles: TStringList);

  TFilesValidator = class
    private
      FBaseFolder: string;          // Основная папка, относительно которой задаются пути в JSON'е
      FRelativeWorkingPath: string; // Папка относительно FBaseFolder, в которой лежат все файлы и папки

      FCriticalSection: _RTL_CRITICAL_SECTION; // Критическая секция для многопоточной работы со списками

      FCheckingsList : TCheckingsList;   // Список файлов и папок на проверку
      FAddonsList    : TAddonsList;      // Список аддонов
      FValidFiles    : TValidFiles;      // Список верных файлов
      FErrorFiles    : TStringList;      // Список файлов, которые не удалось удалить при проверке
      FAbsentFiles   : TAbsentFilesList; // Список отсутствующих файлов

      FLocalFiles          : array of TStringList;
      FDisabledAddonsFiles : TStringList; // Отсортированный для быстрого поиска список файлов из выключенных аддонов

      FWatchers: array of TFilesNotifier;

      procedure AddToErrorFiles(const FilePath: string);
      procedure AddToAbsentFiles(const FileInfo: TValidFileInfo);

      function GetFileHash(const FilePath: string): string;

      procedure FillLocalFilesArray(Multithreading: Boolean);
      procedure TryToDeleteFile(const FilePath: string);
      procedure ValidateFile(const FilePath: string);
      procedure ValidateFilesList(const FilesList: TStringList; Multithreading: Boolean);
      procedure ValidateAllFilesLists(Multithreading: Boolean);
      procedure ClearLocalFilesArray(Multithreading: Boolean);
      procedure FillAbsentFilesList(Multithreading: Boolean);
    public
      property ErrorFiles  : TStringList      read FErrorFiles;
      property AbsentFiles : TAbsentFilesList read FAbsentFiles;

      constructor Create;
      destructor Destroy; override;

      procedure ExtractCheckingsInfo(const CheckingsInfo: TCheckingsInfo);
      procedure ExtractAddonsInfo(const AddonsInfo: TAddonsJSON);
      procedure ExtractValidFilesInfo(const ValidFilesJSON: TValidFilesJSON);
      procedure FillDisabledAddonFiles;
      procedure RemoveDisabledAddonsFromAbsent;
      procedure UpdateAddonsInfo;
      function Validate(const BaseFolder, RelativeWorkingFolder: string; Multithreading: Boolean = True): VALIDATION_STATUS;

      procedure StartFoldersWatching(const ClientFolder: string; OnFilesMismatching: TOnFilesMismatching);
      procedure StopFoldersWatching;

      procedure ClearCheckingsList;
      procedure ClearAddonsList;
      procedure ClearFilesLists;
      procedure ClearValidFilesList;
      procedure Clear;
  end;

implementation

{ TFilesValidator }


// Добавляем файл в список файлов, которые не получилось удалить:
procedure TFilesValidator.AddToErrorFiles(const FilePath: string);
begin
  EnterCriticalSection(FCriticalSection);
  FErrorFiles.Add(FilePath);
  LeaveCriticalSection(FCriticalSection);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Добавляем файл в список отсутствующих файлов:
procedure TFilesValidator.AddToAbsentFiles(const FileInfo: TValidFileInfo);
var
  AbsentFileInfo: TAbsentFileInfo;
begin
  AbsentFileInfo.Size := FileInfo.Size;
  AbsentFileInfo.Link := FileInfo.Link;

  EnterCriticalSection(FCriticalSection);
  FAbsentFiles.Add(AbsentFileInfo);
  LeaveCriticalSection(FCriticalSection);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Получаем хэш файла:
function TFilesValidator.GetFileHash(const FilePath: string): string;
var
  FilePtr: Pointer;
  FileSize: Integer;
begin
  FilePtr := LoadFileToMemory(FilePath, FileSize);
  Result := LowerCase(AnsiToWide(MD5DigestToHex(CalcMD5(FilePtr^, FileSize))));
  FreeMem(FilePtr);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


// Получаем списки локальных файлов для каждого элемента в массиве проверок:
procedure TFilesValidator.FillLocalFilesArray(Multithreading: Boolean);
var
  CheckingsCount: Integer;
  FixedPath: string;
  I: Integer;
begin
  CheckingsCount := Length(FCheckingsList);
  if CheckingsCount = 0 then Exit;

  FixedPath := FixSlashes(FBaseFolder + '\' + FRelativeWorkingPath);

  // Получаем список файлов для каждого элемента в списке проверок:
  SetLength(FLocalFiles, CheckingsCount);
  if Multithreading then
  begin
    TParallel.&For(0, CheckingsCount - 1, procedure(I: Integer)
    begin
      FLocalFiles[I] := TStringList.Create;
      ScanFiles(FixedPath, FCheckingsList[I], FLocalFiles[I]);
    end);
  end
  else
  begin
    for I := 0 to CheckingsCount - 1 do
    begin
      FLocalFiles[I] := TStringList.Create;
      ScanFiles(FixedPath, FCheckingsList[I], FLocalFiles[I]);
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Пробуем удалить, и если не получается - добавляем в список файлов с ошибками:
procedure TFilesValidator.TryToDeleteFile(const FilePath: string);
begin
  if not DeleteFile(FilePath) then AddToErrorFiles(FilePath);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Проверяем файл:
procedure TFilesValidator.ValidateFile(const FilePath: string);
var
  RelativePath  : string;
  FileSize      : Integer;
  ValidFileInfo : TValidFileInfo;
  TempInteger   : Integer;
begin
  RelativePath := GetRelativePath(FilePath, FBaseFolder + '\');

  // Если файла нет в списке верных файлов - удаляем:
  if not FValidFiles.Get(RelativePath, ValidFileInfo) then
  begin
    TryToDeleteFile(FilePath);
    Exit;
  end;

  // Если размер файла не совпадает с верным размером - удаляем:
  FileSize := GetFileSize(FilePath);
  if FileSize <> ValidFileInfo.Size then
  begin
    TryToDeleteFile(FilePath);
    Exit;
  end;

  // Если не совпадает хэш - удаляем:
  if GetFileHash(FilePath) <> LowerCase(ValidFileInfo.Hash) then
  begin
    TryToDeleteFile(FilePath);
    Exit;
  end;

  // Если файл принадлежит выключенному аддону - удаляем:
  if FDisabledAddonsFiles.Count > 0 then
    if FDisabledAddonsFiles.Find(AnsiLowerCase(FilePath), TempInteger) then
      begin
        TryToDeleteFile(FilePath);
        Exit;
      end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Проверяем каждый файл в списке локальных файлов:
procedure TFilesValidator.ValidateFilesList(const FilesList: TStringList; Multithreading: Boolean);
var
  I: Integer;
begin
  if FilesList.Count = 0 then Exit;

  FilesList.Text := FixSlashes(FilesList.Text);

  if Multithreading then
  begin
    TParallel.&For(0, FilesList.Count - 1, procedure(I: Integer)
    begin
      ValidateFile(FilesList[I]);
    end);
  end
  else
  begin
    for I := 0 to FilesList.Count - 1 do
      ValidateFile(FilesList[I]);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Проходимся по всем списка локальных файлов, и проверяем каждый список:
procedure TFilesValidator.ValidateAllFilesLists(Multithreading: Boolean);
var
  LocalFilesEntriesCount: Integer;
  I: Integer;
begin
  LocalFilesEntriesCount := Length(FLocalFiles);
  if LocalFilesEntriesCount = 0 then Exit;

  if Multithreading then
  begin
    TParallel.&For(0, LocalFilesEntriesCount - 1, procedure(I: Integer)
    begin
      ValidateFilesList(FLocalFiles[I], Multithreading);
    end);
  end
  else
  begin
    for I := 0 to LocalFilesEntriesCount - 1 do
      ValidateFilesList(FLocalFiles[I], Multithreading);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Освобождаем память, занятую под списки локальных файлов:
procedure TFilesValidator.ClearLocalFilesArray(Multithreading: Boolean);
var
  LocalFilesEntriesCount: Integer;
  I: Integer;
begin
  LocalFilesEntriesCount := Length(FLocalFiles);
  if LocalFilesEntriesCount = 0 then Exit;

  if Multithreading then
  begin
    TParallel.&For(0, LocalFilesEntriesCount - 1, procedure(I: Integer)
    begin
      FLocalFiles[I].Clear;
      FreeAndNil(FLocalFiles[I]);
    end);
  end
  else
  begin
    for I := 0 to LocalFilesEntriesCount - 1 do
    begin
      FLocalFiles[I].Clear;
      FreeAndNil(FLocalFiles[I]);
    end;
  end;
  SetLength(FLocalFiles, 0);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Получаем список отсутствующих файлов:
procedure TFilesValidator.FillAbsentFilesList(Multithreading: Boolean);
var
  ValidFilesArray: TArray<TValidFileInfo>;
  I: Integer;
begin
  ValidFilesArray := FValidFiles.ValidFilesHashmap.Values.ToArray;
  if Multithreading then
  begin
    TParallel.&For(0, Length(ValidFilesArray) - 1, procedure(I: Integer)
    begin
      if not FileExists(FBaseFolder + '\' + ValidFilesArray[I].Link) then AddToAbsentFiles(ValidFilesArray[I]);
    end);
  end
  else
  begin
    for I := 0 to Length(ValidFilesArray) - 1 do
      if not FileExists(FBaseFolder + '\' + ValidFilesArray[I].Link) then AddToAbsentFiles(ValidFilesArray[I]);
  end;
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


constructor TFilesValidator.Create;
begin
  InitializeCriticalSection(FCriticalSection);
  FValidFiles           := TValidFiles.Create;
  FErrorFiles           := TStringList.Create;
  FDisabledAddonsFiles  := TStringList.Create;
  FAbsentFiles          := TAbsentFilesList.Create;
  Clear;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

destructor TFilesValidator.Destroy;
begin
  Clear;
  FreeAndNil(FValidFiles);
  FreeAndNil(FErrorFiles);
  FreeAndNil(FAbsentFiles);
  FreeAndNil(FDisabledAddonsFiles);
  DeleteCriticalSection(FCriticalSection);
  inherited;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TFilesValidator.ExtractCheckingsInfo(
  const CheckingsInfo: TCheckingsInfo);
begin
  ClearFilesLists;
  ClearCheckingsList;

  if CheckingsInfo = nil then Exit;
  if CheckingsInfo.Count = 0 then Exit;

  SetLength(FCheckingsList, CheckingsInfo.Count);
  TParallel.&For(0, CheckingsInfo.Count - 1, procedure(I: Integer)
  var
    CheckingsElement, ExclusivesElement: TJSONObject;
    ExclusivesArray: TJSONArray;
    J: Integer;
  begin
    CheckingsElement := GetJSONArrayElement(CheckingsInfo, I);

    with FCheckingsList[I] do
    begin
      Path      := GetJSONStringValue (CheckingsElement, 'path');
      Mask      := GetJSONStringValue (CheckingsElement, 'mask');
      Recursive := GetJSONBooleanValue(CheckingsElement, 'recursive');
    end;

    // Получаем список файлов, исключаемых из проверки:
    ExclusivesArray := GetJSONArrayValue(CheckingsElement, 'exclusives');
    if ExclusivesArray = nil then Exit;
    if ExclusivesArray.Count = 0 then Exit;

    FCheckingsList[I].Exclusives := TExclusivesHashmap.Create;
    for J := 0 to ExclusivesArray.Count - 1 do
    begin
      ExclusivesElement := GetJSONArrayElement(ExclusivesArray, J);
      FCheckingsList[I].Exclusives.Add(GetJSONStringValue(ExclusivesElement, 'path'));
    end;
  end);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.ExtractAddonsInfo(
  const AddonsInfo: TAddonsJSON);
begin
  ClearFilesLists;
  ClearAddonsList;

  if AddonsInfo = nil then Exit;
  if AddonsInfo.Count = 0 then Exit;

  SetLength(FAddonsList, AddonsInfo.Count);
  TParallel.&For(0, AddonsInfo.Count - 1, procedure(I: Integer)
  var
    AddonsElement, FilesElement: TJSONObject;
    FilesArray: TJSONArray;
    J: Integer;
  begin
    AddonsElement := GetJSONArrayElement(AddonsInfo, I);

    FAddonsList[I] := TAddonInfo.Create;
    with FAddonsList[I] do
    begin
      Id        := GetJSONStringValue (AddonsElement, 'id');
      Name      := GetJSONStringValue (AddonsElement, 'name');
      Enabled   := GetJSONBooleanValue(AddonsElement, 'enabled');
    end;

    // Получаем список файлов
    FilesArray := GetJSONArrayValue(AddonsElement, 'files');
    if FilesArray = nil then Exit;
    if FilesArray.Count = 0 then Exit;

    for J := 0 to FilesArray.Count - 1 do
    begin
      FilesElement := GetJSONArrayElement(FilesArray, J);
      FAddonsList[I].Files.Add(GetJSONStringValue(FilesElement, 'name'));
    end;
  end);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.ExtractValidFilesInfo(
  const ValidFilesJSON: TValidFilesJSON);
var
  I : Integer;
  ValidFileJSON   : TJSONObject;
  ValidFileInfo   : TValidFileInfo;
begin
  ClearFilesLists;
  ClearValidFilesList;

  if ValidFilesJSON = nil then Exit;
  if ValidFilesJSON.Count = 0 then Exit;

  // Парсим список верных файлов:
  for I := 0 to ValidFilesJSON.Count - 1 do
  begin
    ValidFileJSON := GetJSONArrayElement(ValidFilesJSON, I);

    // Заполняем хэшмап "относительный путь" -> "информация"
    ValidFileInfo.Size := GetJSONIntValue   (ValidFileJSON, 'size');
    ValidFileInfo.Hash := GetJSONStringValue(ValidFileJSON, 'hash');
    ValidFileInfo.Link := GetJSONStringValue(ValidFileJSON, 'path');

    // Добавляем файл
    FValidFiles.Add(ValidFileInfo.Link, ValidFileInfo);
  end;
end;

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

// Эта функция вызывается при запуске клиента дважды: при проверке файлов клиента и при проверке файлов JVM
function TFilesValidator.Validate(const BaseFolder,
  RelativeWorkingFolder: string; Multithreading: Boolean): VALIDATION_STATUS;
{$IFDEF DEBUG}
var
  I: Integer;
  AbsentFilesList: TStringList;
{$ENDIF}
begin

  if FValidFiles.ValidFilesHashmap.Count = 0 then Exit(VALIDATION_STATUS_SUCCESS);

  FBaseFolder                := BaseFolder;
  FRelativeWorkingPath       := RelativeWorkingFolder;

  // Чистим списки файлов:
  ClearFilesLists;

  UpdateAddonsInfo(); // Обновляем информацию о выключенных аддонах
  FillDisabledAddonFiles(); // Собираем файлы из выключенных аддонов в один список

  // Делаем проверку файлов, удаляем не прошедшие проверку:
  FillLocalFilesArray(Multithreading);          // Заполняем список локальных файлов в соответствии с проверками
  ValidateAllFilesLists(Multithreading);        // Проходимся по всем спискам локальных файлов и проверяем каждый файл в них
  ClearLocalFilesArray(Multithreading);         // Освобождаем память, занятую под списки локальных файлов

  FillAbsentFilesList(Multithreading); // Получаем список недостающих файлов:

  RemoveDisabledAddonsFromAbsent(); // Удаляем файлы выключенных аддонов из списка недостающих файлов, чтобы не закачивать их заново

  {$IFDEF DEBUG}
    if FErrorFiles.Count > 0 then FErrorFiles.SaveToFile('ErrorFiles.txt');

    if FAbsentFiles.Count > 0 then
    begin
      AbsentFilesList := TStringList.Create;
      AbsentFilesList.Clear;
      for I := 0 to FAbsentFiles.Count - 1 do
        AbsentFilesList.Add(FAbsentFiles[I].Link);
      AbsentFilesList.SaveToFile('AbsentFiles.txt');
      FreeAndNil(AbsentFilesList);
    end;
  {$ENDIF}

  // Возвращаем результат:
  if FErrorFiles.Count  > 0 then Exit(VALIDATION_STATUS_DELETION_ERROR);
  if FAbsentFiles.Count > 0 then Exit(VALIDATION_STATUS_NEED_UPDATE);
  Result := VALIDATION_STATUS_SUCCESS;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TFilesValidator.StartFoldersWatching(const ClientFolder: string;
  OnFilesMismatching: TOnFilesMismatching);
var
  CheckingsCount: Integer;
  I: Integer;
  ExclusivesStr: string;
begin
  StopFoldersWatching;

  CheckingsCount := Length(FCheckingsList);
  if CheckingsCount = 0 then Exit;

  SetLength(FWatchers, CheckingsCount);
  for I := 0 to CheckingsCount - 1 do
  begin
    ExclusivesStr := '';
    if Assigned(FCheckingsList[I].Exclusives) then
      ExclusivesStr := GenerateDelimiteredData(TStringArray(FCheckingsList[I].Exclusives.Hashmap.Keys.ToArray), ',');

    FWatchers[I] := TFilesNotifier.Create(ClientFolder + '\' + FCheckingsList[I].Path, FCheckingsList[I].Mask, ExclusivesStr);

    FWatchers[I].OnDirChange := procedure(const FilesNotifier: TFilesNotifier; const NotifyStruct: TNotifyStruct)
    var
      I: Integer;
    begin
      ClearFilesLists;
      if NotifyStruct.ChangesCount = 0 then Exit;

      for I := 0 to NotifyStruct.ChangesCount - 1 do
        if NotifyStruct.Changes[I].Action <> FILE_ACTION_REMOVED then
          ValidateFile(FilesNotifier.BaseFolder + '\' + NotifyStruct.Changes[I].FileName);

      if FErrorFiles.Count > 0 then
        if Assigned(OnFilesMismatching) then
          OnFilesMismatching(FErrorFiles);
    end;

    FWatchers[I].StartWatching(FCheckingsList[I].Recursive);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


procedure TFilesValidator.StopFoldersWatching;
var
  WatchersCount: Integer;
begin
  WatchersCount := Length(FWatchers);
  if WatchersCount > 0 then TParallel.&For(0, WatchersCount - 1, procedure(I: Integer)
  begin
    if Assigned(FWatchers[I]) then
    begin
      FWatchers[I].StopWatching;
      FreeAndNil(FWatchers[I]);
    end;
  end);
  SetLength(FWatchers, 0);
end;


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

procedure TFilesValidator.RemoveDisabledAddonsFromAbsent();
var
  I           : Integer;
  TempInteger : Integer;
begin
  if FDisabledAddonsFiles.Count > 0 then
  begin
    I := 0;
    while I < FAbsentFiles.Count do
      if FDisabledAddonsFiles.Find(AnsiLowerCase(FixSlashes(FBaseFolder + '\' + FAbsentFiles[I].Link)), TempInteger) then
        FAbsentFiles.Delete(I) else
        Inc(I);
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.FillDisabledAddonFiles();
var
  AddonsCount, AddonFilesCount: Integer;
  I, J: Integer;
begin
  FDisabledAddonsFiles.Clear;
  AddonsCount := Length(FAddonsList);
  if AddonsCount = 0 then Exit;

  for I := 0 to AddonsCount - 1 do
  begin
    if not FAddonsList[I].Enabled then
      begin
      AddonFilesCount := FAddonsList[I].Files.Count;
      if AddonFilesCount > 0 then
        for J := 0 to AddonFilesCount - 1 do
          FDisabledAddonsFiles.Add(AnsiLowerCase(FixSlashes(FBaseFolder + '\' + FRelativeWorkingPath + '\' + FAddonsList[I].Files[J])));
      end;
  end;
  FDisabledAddonsFiles.Sort; // Сортируем для быстрого поиска
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.UpdateAddonsInfo;
var
  AddonsCount: Integer;
  I: Integer;
begin
  AddonsCount := Length(FAddonsList);
  if AddonsCount = 0 then Exit;
  
  for I := 0 to AddonsCount - 1 do
    FAddonsList[i].Update;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.ClearCheckingsList;
var
  CheckingsListCount: Integer;
begin
  CheckingsListCount := Length(FCheckingsList);
  if CheckingsListCount = 0 then Exit;

  TParallel.&For(0, CheckingsListCount - 1, procedure(I: Integer)
  begin
    FCheckingsList[I].Path := '';
    FCheckingsList[I].Mask := '';
    FCheckingsList[I].Recursive := False;
    if Assigned(FCheckingsList[I].Exclusives) then
    begin
      FCheckingsList[I].Exclusives.Clear;
      FreeAndNil(FCheckingsList[I].Exclusives);
    end;
  end);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.ClearAddonsList;
var
  AddonsListCount: Integer;
  I: Integer;
begin
  AddonsListCount := Length(FAddonsList);
  if AddonsListCount = 0 then Exit;

  for I := 0 to AddonsListCount - 1 do
    FAddonsList[I].Clear;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.ClearFilesLists;
begin
  FErrorFiles.Clear;
  FAbsentFiles.Clear;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.ClearValidFilesList;
begin
  FValidFiles.Clear;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TFilesValidator.Clear;
begin
  StopFoldersWatching;
  ClearFilesLists;
  ClearValidFilesList;
  ClearCheckingsList;
  ClearAddonsList;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TAddonInfo.Update;
begin
  FEnabled := ReadBooleanFromRegistry(RegistryPath, 'addon_' + FId, FEnabled);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TAddonInfo.Clear;
begin
  FFiles.Clear;
  Id := '';
  FName := '';
  FEnabled := false;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TAddonInfo.Create;
begin
  FFiles := TStringList.Create;
  Clear;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

destructor TAddonInfo.Destroy;
begin
  Clear;
  FreeAndNil(FFiles);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

end.
