program ScannerGUIProject;

// *** Ths source is distributed under Apache 2.0 ***

uses
  Vcl.Forms,
  ufMain in 'ufMain.pas' {frmMain},
  uScanner in 'uScanner.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
