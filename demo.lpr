program demo;

{$MODE Delphi}

uses
  {$ifdef unix}
    cthreads,
    cmem, // the c memory manager is on some systems much faster for multi-threading
  {$endif}
  Forms,
  Interfaces,
  main in 'main.pas' {Form1},
  GrEn in 'GrEn.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
