program calculatorProject;

// Source code related to the second half chapter 6 and 7 for the book:
// Writing an Interpreter in Object Pascal: Part 1
// Uses a custom TScanner class comapred to the one describe in Chapter 3


{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Math,
  uScanner in 'uScanner.pas',
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
  writeln ('Only supports expressions, no assignment of variable names, e.g');
  writeln ('2+3,  4/(6-7),  4*3+8E-4*50, 2^3, ---4');
  writeln ('Tyep quit to exit');
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
             sc.nextToken;
             writeln (sy.expression:12:8);
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

