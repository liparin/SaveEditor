unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, ComCtrls, Menus,
  Dialogs, ExtCtrls,
  SaveTableLoader, SaveFileIO, HashUtils;

type
  TFormMain = class(TForm)
    MainMenu: TMainMenu;
    MenuFile: TMenuItem;
    MiLoadTable: TMenuItem;
    MiLoadSave: TMenuItem;
    N1: TMenuItem;
    MiExit: TMenuItem;
    MenuHelp: TMenuItem;
    MiAbout: TMenuItem;
    PanelTop: TPanel;
    BtnLoadTable: TButton;
    BtnLoadSave: TButton;
    BtnSave: TButton;
    ValueGrid: TStringGrid;
    StatusBar: TStatusBar;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnLoadTableClick(Sender: TObject);
    procedure BtnLoadSaveClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure MiLoadTableClick(Sender: TObject);
    procedure MiLoadSaveClick(Sender: TObject);
    procedure MiExitClick(Sender: TObject);
    procedure MiAboutClick(Sender: TObject);
  private
    FTable: TSaveTable;
    FSave: TSaveFile;
    procedure PopulateGrid;
    procedure ApplyGridToSave;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FTable := nil;
  FSave := nil;
  StatusBar.SimpleText := 'Ready';
  ValueGrid.Cells[0, 0] := 'Name';
  ValueGrid.Cells[1, 0] := 'Value';
  ValueGrid.Cells[2, 0] := 'Type';
  ValueGrid.Cells[3, 0] := 'Offset';
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FSave) then FSave.Free;
  if Assigned(FTable) then FTable.Free;
end;

procedure TFormMain.BtnLoadTableClick(Sender: TObject);
begin
  OpenDialog.Filter := 'XML Tables|*.xml';
  OpenDialog.Title := 'Load Table';
  if OpenDialog.Execute then
  begin
    if Assigned(FTable) then FreeAndNil(FTable);
    FTable := TSaveTable.Create;
    try
      FTable.LoadFromFile(OpenDialog.FileName);
      Caption := 'Save Editor - ' + FTable.GameName;
      StatusBar.SimpleText := 'Table loaded: ' + ExtractFileName(OpenDialog.FileName);
    except
      on E: Exception do
      begin
        ShowMessage('Error loading table: ' + E.Message);
        FreeAndNil(FTable);
      end;
    end;
  end;
end;

procedure TFormMain.BtnLoadSaveClick(Sender: TObject);
begin
  if not Assigned(FTable) then
  begin
    ShowMessage('Load a table first.');
    Exit;
  end;
  OpenDialog.Filter := 'All files|*.*';
  OpenDialog.Title := 'Load Save';
  if OpenDialog.Execute then
  begin
    if Assigned(FSave) then FreeAndNil(FSave);
    FSave := TSaveFile.Create;
    FSave.LittleEndian := (FTable.Endian = 'little');
    try
      FSave.LoadFromFile(OpenDialog.FileName);
      PopulateGrid;
      StatusBar.SimpleText := 'Save loaded: ' + ExtractFileName(OpenDialog.FileName) +
        ' (' + IntToStr(Length(FSave.Data)) + ' bytes)';
    except
      on E: Exception do
      begin
        ShowMessage('Error loading save: ' + E.Message);
        FreeAndNil(FSave);
      end;
    end;
  end;
end;

procedure TFormMain.PopulateGrid;
var
  i: Integer;
  Entry: TSaveEntry;
  TypeStr: string;
begin
  ValueGrid.RowCount := FTable.Entries.Count + 1;
  for i := 0 to FTable.Entries.Count - 1 do
  begin
    Entry := TSaveEntry(FTable.Entries[i]);
    ValueGrid.Cells[0, i + 1] := Entry.Name;
    ValueGrid.Cells[3, i + 1] := IntToStr(Entry.Offset);

    case Entry.EntryType of
      etInt32:
      begin
        TypeStr := 'int32';
        ValueGrid.Cells[1, i + 1] := IntToStr(FSave.ReadInt32(Entry.Offset));
      end;
      etFloat:
      begin
        TypeStr := 'float';
        ValueGrid.Cells[1, i + 1] := FloatToStr(FSave.ReadFloat(Entry.Offset));
      end;
      etString:
      begin
        TypeStr := 'string';
        ValueGrid.Cells[1, i + 1] := FSave.ReadString(Entry.Offset, Entry.Length);
      end;
      etBytes:
      begin
        TypeStr := 'bytes';
        ValueGrid.Cells[1, i + 1] := '0x' + IntToHex(FSave.ReadInt32(Entry.Offset), 8);
      end;
      etArray:
      begin
        TypeStr := 'array';
        ValueGrid.Cells[1, i + 1] := '[array: ' + IntToStr(Entry.Count) + ' items]';
      end;
    end;
    ValueGrid.Cells[2, i + 1] := TypeStr;
  end;
end;

procedure TFormMain.ApplyGridToSave;
var
  i: Integer;
  Entry: TSaveEntry;
  ValueStr: string;
begin
  for i := 0 to FTable.Entries.Count - 1 do
  begin
    Entry := TSaveEntry(FTable.Entries[i]);
    ValueStr := ValueGrid.Cells[1, i + 1];
    case Entry.EntryType of
      etInt32:  FSave.WriteInt32(Entry.Offset, StrToIntDef(ValueStr, 0));
      etFloat:  FSave.WriteFloat(Entry.Offset, StrToFloatDef(ValueStr, 0));
      etString: FSave.WriteString(Entry.Offset, ValueStr, Entry.Length);
      etBytes:  FSave.WriteBytes(Entry.Offset, FSave.ReadBytes(Entry.Offset, Entry.Length));
    end;
  end;
end;

procedure TFormMain.BtnSaveClick(Sender: TObject);
var
  BakName: string;
begin
  if not Assigned(FSave) then Exit;

  ApplyGridToSave;

  if FTable.HashAlgorithm <> '' then
  begin
    if FTable.HashAlgorithm = 'crc32' then
      FSave.WriteInt32(FTable.HashOffset,
        Integer(CalcCRC32(FSave.Data, FTable.HashTargetOffset, FTable.HashTargetLength)));
  end;

  BakName := ChangeFileExt(OpenDialog.FileName, '.bak');
  if FileExists(OpenDialog.FileName) then
    CopyFile(OpenDialog.FileName, BakName);

  SaveDialog.FileName := ExtractFileName(OpenDialog.FileName);
  if SaveDialog.Execute then
  begin
    FSave.SaveToFile(SaveDialog.FileName);
    StatusBar.SimpleText := 'Saved: ' + SaveDialog.FileName;
  end;
end;

procedure TFormMain.MiLoadTableClick(Sender: TObject);
begin
  BtnLoadTableClick(Sender);
end;

procedure TFormMain.MiLoadSaveClick(Sender: TObject);
begin
  BtnLoadSaveClick(Sender);
end;

procedure TFormMain.MiExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.MiAboutClick(Sender: TObject);
begin
  ShowMessage('Save Editor' + #13#10 + 'XML-table based save file editor.');
end;

end.
