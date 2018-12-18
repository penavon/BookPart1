program REPL_SyntaxAnalysis;

// Source code for chapter 6 and 7 for the book:

// Writing an Interpreter in Object Pascal: Part 1

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uScanner in '..\LexicalAnalysis_Chap3_4_5\uScanner.pas',
  uSyntaxAnalysis in 'uSyntaxAnalysis.pas';

 const
   RHODUS_VERSION = '1.0';

var sourceCode : string;
    sc : TScanner;
    sy : TSyntaxAnalysis;


procedure displayWelcome;
begin
  writeln ('Welcome to Rhodus Syntax Analysis Console, Version ', RHODUS_VERSION);
  writeln ('Data and Time: ', dateToStr (Date), ', ', timeToStr (Time));
end;


procedure displayPrompt;
begin
  write ('>> ');
end;


begin
  sc := TScanner.Create;
  try
    sy := TSyntaxAnalysis.Create (sc);
    try
      displayWelcome;
      while True do
        begin
        displayPrompt;
        readln (sourceCode);
        if sourceCode = 'quit' then
           break;

        if sourceCode <> '' then
           begin
           sc.scanString(sourceCode);
           try
             sy.myProgram;
           except
             on e:exception do
                writeln ('Error: ' + e.Message);
           end;
           end;
        end;
      writeln ('Press any key to exit');
      readln;
    finally
      sy.Free;
    end;
  finally
    sc.Free;
  end;
end.

