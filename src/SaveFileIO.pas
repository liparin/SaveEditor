unit SaveFileIO;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TSaveFile = class
  private
    FData: TBytes;
    FLittleEndian: Boolean;
  public
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    function Size: Int64;
    function ReadInt32(Offset: Int64): Integer;
    function ReadFloat(Offset: Int64): Single;
    function ReadString(Offset: Int64; Length: Integer): string;
    function ReadBytes(Offset: Int64; Length: Integer): TBytes;
    procedure WriteInt32(Offset: Int64; Value: Integer);
    procedure WriteFloat(Offset: Int64; Value: Single);
    procedure WriteString(Offset: Int64; const Value: string; MaxLength: Integer);
    procedure WriteBytes(Offset: Int64; const Value: TBytes);
    property Data: TBytes read FData;
    property LittleEndian: Boolean read FLittleEndian write FLittleEndian;
  end;

implementation

procedure TSaveFile.LoadFromFile(const AFileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(FData, FS.Size);
    if FS.Size > 0 then
      FS.ReadBuffer(FData[0], FS.Size);
  finally
    FS.Free;
  end;
end;

procedure TSaveFile.SaveToFile(const AFileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(FData) > 0 then
      FS.WriteBuffer(FData[0], Length(FData));
  finally
    FS.Free;
  end;
end;

function TSaveFile.Size: Int64;
begin
  Result := Length(FData);
end;

function Swap32(Value: Integer): Integer;
begin
  Result := ((Value and $FF) shl 24) or
            ((Value and $FF00) shl 8) or
            ((Value and $FF0000) shr 8) or
            ((Value and $FF000000) shr 24);
end;

function Swap32Single(Value: Single): Single;
var
  I: Integer absolute Value;
  O: Integer absolute Result;
begin
  O := Swap32(I);
end;

function TSaveFile.ReadInt32(Offset: Int64): Integer;
begin
  if Offset + 4 > Length(FData) then
    Exit(0);
  Move(FData[Offset], Result, 4);
  if not FLittleEndian then
    Result := Swap32(Result);
end;

function TSaveFile.ReadFloat(Offset: Int64): Single;
begin
  if Offset + 4 > Length(FData) then
    Exit(0);
  Move(FData[Offset], Result, 4);
  if not FLittleEndian then
    Result := Swap32Single(Result);
end;

function TSaveFile.ReadString(Offset: Int64; Length: Integer): string;
var
  Raw: TBytes;
  i: Integer;
  CutPos: Integer;
begin
  if Offset + Length > System.Length(FData) then
    Length := System.Length(FData) - Offset;
  if Length <= 0 then
    Exit('');

  SetLength(Raw, Length);
  Move(FData[Offset], Raw[0], Length);

  CutPos := Length;
  for i := 0 to Length - 1 do
  begin
    if Raw[i] = 0 then
    begin
      CutPos := i;
      Break;
    end;
  end;
  SetLength(Raw, CutPos);
  Result := TEncoding.UTF8.GetString(Raw);
end;

function TSaveFile.ReadBytes(Offset: Int64; Length: Integer): TBytes;
begin
  if Offset + Length > System.Length(FData) then
    Length := System.Length(FData) - Offset;
  if Length <= 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  SetLength(Result, Length);
  Move(FData[Offset], Result[0], Length);
end;

procedure TSaveFile.WriteInt32(Offset: Int64; Value: Integer);
var
  Tmp: Integer;
begin
  if Offset + 4 > System.Length(FData) then
    Exit;
  Tmp := Value;
  if not FLittleEndian then
    Tmp := Swap32(Tmp);
  Move(Tmp, FData[Offset], 4);
end;

procedure TSaveFile.WriteFloat(Offset: Int64; Value: Single);
var
  Tmp: Single;
begin
  if Offset + 4 > System.Length(FData) then
    Exit;
  Tmp := Value;
  if not FLittleEndian then
    Tmp := Swap32Single(Tmp);
  Move(Tmp, FData[Offset], 4);
end;

procedure TSaveFile.WriteString(Offset: Int64; const Value: string; MaxLength: Integer);
var
  Raw: TBytes;
  i: Integer;
begin
  if Offset + MaxLength > System.Length(FData) then
    Exit;
  SetLength(Raw, MaxLength);
  for i := 0 to MaxLength - 1 do
    Raw[i] := 0;
  Raw := TEncoding.UTF8.GetBytes(Value);
  if System.Length(Raw) > MaxLength then
    SetLength(Raw, MaxLength);
  Move(Raw[0], FData[Offset], System.Length(Raw));
end;

procedure TSaveFile.WriteBytes(Offset: Int64; const Value: TBytes);
begin
  if Offset + System.Length(Value) > System.Length(FData) then
    Exit;
  Move(Value[0], FData[Offset], System.Length(Value));
end;

end.
