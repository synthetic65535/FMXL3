unit ValidationTypes;

interface

uses
  SysUtils, Generics.Collections, StringsAPI;

type
  // Информация о верном файле из JSON'а:
  TValidFileInfo = record
    Size: Integer;
    Hash: string;
    Link: string; // путь относительно основных рабочих папок на сервере и на локальной машине
  end;
  TValidFilesHashmap = TDictionary<string, TValidFileInfo>;

  // Информация о файле, который нужно обновить:
  TAbsentFileInfo = record
    Size: Integer;
    Link: string;
  end;
  TAbsentFilesList = TList<TAbsentFileInfo>;

  // Хэшмап верных файлов:
  TValidFiles = class
    private
      FValidFilesHashmap: TValidFilesHashmap;
    public
      property ValidFilesHashmap: TValidFilesHashmap read FValidFilesHashmap;

      constructor Create;
      destructor Destroy; override;

      procedure Add(const RelativePath: string; const FileInfo: TValidFileInfo);
      procedure Remove(const RelativePath: string);
      function  Get(const RelativePath: string; out   FileInfo: TValidFileInfo): Boolean;
      procedure Clear;
  end;

implementation


{ TValidFiles }

constructor TValidFiles.Create;
begin
  FValidFilesHashmap := TValidFilesHashmap.Create;
  Clear;
end;

destructor TValidFiles.Destroy;
begin
  Clear;
  FreeAndNil(FValidFilesHashmap);
  inherited;
end;

procedure TValidFiles.Add(const RelativePath: string;
  const FileInfo: TValidFileInfo);
var
  FixedPath: string;
begin
  FixedPath := LowerCase(FixSlashes(RelativePath));
  FValidFilesHashmap.Add(FixedPath, FileInfo);
end;

procedure TValidFiles.Remove(const RelativePath: string);
var
  FixedPath: string;
begin
  FixedPath := LowerCase(FixSlashes(RelativePath));
  FValidFilesHashmap.Remove(FixedPath);
end;

function TValidFiles.Get(const RelativePath: string;
  out FileInfo: TValidFileInfo): Boolean;
var
  FixedPath: string;
begin
  FileInfo.Size := 0;
  FileInfo.Hash := '';
  FileInfo.Link := '';

  FixedPath := LowerCase(FixSlashes(RelativePath));
  Result := FValidFilesHashmap.TryGetValue(FixedPath, FileInfo);
end;

procedure TValidFiles.Clear;
begin
  FValidFilesHashmap.Clear;
end;

end.
