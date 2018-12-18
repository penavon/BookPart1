unit ufMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent,
  IdComponent, IdUDPBase, IdUDPClient, Vcl.Grids, Vcl.ExtDlgs, uScanner;

type
  TfrmMain = class(TForm)
    btnStart1: TButton;
    memoInput1: TMemo;
    memoInput2: TMemo;
    btnStart2: TButton;
    StringGrid: TStringGrid;
    moResult: TMemo;
    btnLoad: TButton;
    OpenTextFileDialog: TOpenTextFileDialog;
    procedure btnStart1Click(Sender: TObject);
    procedure btnStart2Click(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure prepareOutputGrid;
    procedure runLexicalScanner (sc : TScanner);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.prepareOutputGrid;
var i : integer;
begin
  for i := 0 to StringGrid.ColCount - 1 do
      StringGrid.Cols[i].Clear;
  StringGrid.RowCount := 100;
  StringGrid.Cells[0,0] := 'Value';
  StringGrid.Cells[1,0] := 'Line Number';
  StringGrid.Cells[2,0] := 'Column Number';
  moResult.Clear;
end;


procedure TfrmMain.runLexicalScanner (sc : TScanner);
var rowCount : integer;
begin
  rowCount := 1;
  try
    sc.nextToken;
    while sc.token <> tEndOfStream do
          begin
          StringGrid.Cells[0,rowCount] := sc.TokenToString;
          StringGrid.Cells[1,rowCount] := inttostr (sc.tokenRecord.lineNumber);
          StringGrid.Cells[2,rowCount] := inttostr (sc.tokenRecord.columnNumber);
          sc.nextToken;
          inc (rowCount);
          end;
  except
     on e: Exception do
        begin
        moResult.Clear;
        moResult.Lines.Add ('error: ' + e.Message + ' near Line: ' + inttostr(sc.tokenRecord.lineNumber) + ', column: ' + inttostr (sc.tokenRecord.columnNumber));
        exit;
        end;
  end;
  moResult.Lines.Add('Successful');
end;


procedure TfrmMain.btnLoadClick(Sender: TObject);
var sc : TScanner;
begin
  if OpenTextFileDialog.Execute then
     begin
     prepareOutputGrid;
     memoInput2.Lines.LoadFromFile(OpenTextFileDialog.FileName);

     sc := TScanner.create();
     sc.scanFile(OpenTextFileDialog.FileName);
     try
       runLexicalScanner (sc);
     finally
        sc.Free;
     end;
     end;
end;


procedure TfrmMain.btnStart1Click(Sender: TObject);
var sc : TScanner;
begin
  prepareOutputGrid;

  sc := TScanner.create();
   try
    sc.scanString(memoInput1.text);
    runLexicalScanner (sc);
  finally
    sc.Free;
  end;
end;


procedure TfrmMain.btnStart2Click(Sender: TObject);
var sc : TScanner;
    rowCount, i : integer;
begin
  prepareOutputGrid;

  sc := TScanner.create();
  try
    sc.scanString(memoInput2.text);
    runLexicalScanner (sc);
   finally
      sc.Free;
  end;
end;

end.
