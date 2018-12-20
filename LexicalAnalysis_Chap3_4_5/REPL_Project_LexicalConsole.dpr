program REPL_Project_LexicalConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uScanner in 'uScanner.pas';

const
   RHODUS_VERSION = '1.0';

var sourceCode : string;
    sc : TScanner;

procedure displayWelcome;
begin
  writeln ('Welcome to Rhodus Lexical Analysis Console, Version ', RHODUS_VERSION);
  writeln ('Data and Time: ', dateToStr (Date), ', ', timeToStr (Time));
  writeln ('Type quit to exit');
end;

procedure displayPrompt;
begin
  write ('>> ');
end;

begin
  sc := TScanner.Create;
  try
    displayWelcome;
    while True do
      begin
      displayPrompt;
      readln (sourceCode);
      if sourceCode = 'quit' then
         break;

      sc.scanString(sourceCode); ;
      try
        sc.nextToken;
        while sc.token <> tEndofStream do
              begin
              writeln (sc.tokenToString);
              sc.nextToken
              end;
      except
        on e:exception do
           writeln ('Error: ' + e.Message);
      end;
      end;

    writeln ('Press any key to exit');
    readln;
  finally
    sc.Free;
  end;
end.

