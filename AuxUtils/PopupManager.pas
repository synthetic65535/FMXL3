unit PopupManager;

interface

uses
  SysUtils, Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Menus, FMX.ImgList;

type
  TPopupMenuBinder = class
    private type
      TOnPopup = procedure(Sender: TObject) of object;
    private
      FOnPopup    : TOnPopup;
      FObjectList : TFMXObjectList;
      FMenuItems  : TList<TMenuItem>;
    public
      constructor Create(const SourcePopupMenu: TPopupMenu);
      destructor Destroy; override;
      procedure AddItem(const MenuItem: TMenuItem);
      procedure Bind(const Control: TControl; Tag: Integer = 0);
  end;

implementation

{ TPopupMenuBinder }

constructor TPopupMenuBinder.Create(const SourcePopupMenu: TPopupMenu);
var
  I: Integer;
begin
  FOnPopup := SourcePopupMenu.OnPopup;
  FObjectList := TFMXObjectList.Create;
  SourcePopupMenu.AddObjectsToList(FObjectList);
  FMenuItems := TList<TMenuItem>.Create;

  if FObjectList.Count = 0 then Exit;

  for I := 0 to FObjectList.Count - 1 do
    if FObjectList.Items[I] is TMenuItem then
      FMenuItems.Add(TMenuItem(FObjectList.Items[I]));
end;

destructor TPopupMenuBinder.Destroy;
begin
  FMenuItems.Clear;
  FreeAndNil(FMenuItems);
  FreeAndNil(FObjectList);
  inherited;
end;

procedure TPopupMenuBinder.AddItem(const MenuItem: TMenuItem);
begin
  FMenuItems.Add(MenuItem);
end;

procedure TPopupMenuBinder.Bind(const Control: TControl; Tag: Integer);
var
  I: Integer;
  MenuItem: TMenuItem;
  CustomPopupMenu: TPopupMenu;
begin
  CustomPopupMenu := TPopupMenu.Create(Control);
  CustomPopupMenu.OnPopup := FOnPopup;
  Control.PopupMenu := CustomPopupMenu;
  Control.Parent := Control;
  Control.PopupMenu.Tag := Tag;
  if FMenuItems.Count = 0 then Exit;

  for I := 0 to FMenuItems.Count - 1 do
  begin
    MenuItem := TMenuItem.Create(Control.PopupMenu);
    MenuItem.Parent     := Control.PopupMenu;
    MenuItem.IsChecked  := FMenuItems.Items[I].IsChecked;
    MenuItem.Tag        := Tag;
    MenuItem.TagString  := FMenuItems.Items[I].TagString;
    MenuItem.Text       := FMenuItems.Items[I].Text;
    MenuItem.Bitmap     := FMenuItems.Items[I].Bitmap;
    MenuItem.OnClick    := FMenuItems.Items[I].OnClick;
  end;
end;

end.
