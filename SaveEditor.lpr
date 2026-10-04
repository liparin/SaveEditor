program SaveEditor;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces,
  Forms, MainForm, SaveTableLoader, SaveFileIO, HashUtils;

{$R *.res}

begin
  RequireDerivedFormProperty := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, FormMain);
  Application.Run;
end.
