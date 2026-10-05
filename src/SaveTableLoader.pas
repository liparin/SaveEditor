unit SaveTableLoader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, XMLRead;

type
  TEntryType = (etInt32, etFloat, etString, etArray, etBytes);

  TSaveEntry = class
    Name: string;
    Offset: Int64;
    EntryType: TEntryType;
    Length: Integer;
    Count: Integer;
    EntrySize: Integer;
    Children: TList;
    constructor Create;
    destructor Destroy; override;
  end;

  TSaveTable = class
    GameName: string;
    Version: string;
    Endian: string;
    HashAlgorithm: string;
    HashOffset: Int64;
    HashLength: Integer;
    HashTargetOffset: Int64;
    HashTargetLength: Int64;
    HasHash: Boolean;
    Entries: TList;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);
  end;

function EntryTypeToString(AType: TEntryType): string;

implementation

constructor TSaveEntry.Create;
begin
  Children := TList.Create;
end;

destructor TSaveEntry.Destroy;
var
  i: Integer;
begin
  for i := 0 to Children.Count - 1 do
    TSaveEntry(Children[i]).Free;
  Children.Free;
  inherited;
end;

constructor TSaveTable.Create;
begin
  Entries := TList.Create;
  HasHash := False;
end;

destructor TSaveTable.Destroy;
var
  i: Integer;
begin
  for i := 0 to Entries.Count - 1 do
    TSaveEntry(Entries[i]).Free;
  Entries.Free;
  inherited;
end;

function EntryTypeToString(AType: TEntryType): string;
begin
  case AType of
    etInt32:  Result := 'int32';
    etFloat:  Result := 'float';
    etString: Result := 'string';
    etArray:  Result := 'array';
    etBytes:  Result := 'bytes';
    else      Result := 'unknown';
  end;
end;

function StrToEntryType(const S: string): TEntryType;
begin
  if S = 'int32' then
    Result := etInt32
  else if S = 'float' then
    Result := etFloat
  else if S = 'string' then
    Result := etString
  else if S = 'array' then
    Result := etArray
  else if S = 'bytes' then
    Result := etBytes
  else
    Result := etBytes;
end;

procedure ParseEntryNodes(ParentNode: TDOMNode; EntryList: TList);
var
  Node: TDOMNode;
  Entry: TSaveEntry;
  AttrVal: string;
begin
  Node := ParentNode.FirstChild;
  while Node <> nil do
  begin
    if Node.NodeName = 'Entry' then
    begin
      Entry := TSaveEntry.Create;
      Entry.Name := Node.GetAttribute('name');

      AttrVal := Node.GetAttribute('offset');
      Entry.Offset := StrToInt64Def(AttrVal, 0);

      AttrVal := Node.GetAttribute('type');
      Entry.EntryType := StrToEntryType(AttrVal);

      AttrVal := Node.GetAttribute('length');
      Entry.Length := StrToIntDef(AttrVal, 0);

      AttrVal := Node.GetAttribute('count');
      Entry.Count := StrToIntDef(AttrVal, 0);

      AttrVal := Node.GetAttribute('entrySize');
      Entry.EntrySize := StrToIntDef(AttrVal, 0);

      if Entry.EntryType = etArray then
        ParseEntryNodes(Node, Entry.Children);

      EntryList.Add(Entry);
    end;
    Node := Node.NextSibling;
  end;
end;

procedure TSaveTable.LoadFromFile(const AFileName: string);
var
  Doc: TXMLDocument;
  Root, HashNode, EntriesNode: TDOMNode;
begin
  ReadXMLFile(Doc, AFileName);
  try
    Root := Doc.DocumentElement;
    GameName := Root.GetAttribute('game');
    Version := Root.GetAttribute('version');
    Endian := Root.GetAttribute('endian');

    HashNode := Doc.GetElementsByTagName('Hash').Item[0];
    if HashNode <> nil then
    begin
      HasHash := True;
      HashAlgorithm := HashNode.GetAttribute('algorithm');
      HashOffset := StrToInt64Def(HashNode.GetAttribute('offset'), 0);
      HashLength := StrToIntDef(HashNode.GetAttribute('length'), 0);
      HashTargetOffset := StrToInt64Def(HashNode.GetAttribute('targetOffset'), 0);
      HashTargetLength := StrToInt64Def(HashNode.GetAttribute('targetLength'), 0);
    end;

    EntriesNode := Doc.GetElementsByTagName('Entries').Item[0];
    if EntriesNode <> nil then
      ParseEntryNodes(EntriesNode, Entries);
  finally
    Doc.Free;
  end;
end;

end.
