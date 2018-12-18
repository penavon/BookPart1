program calculatorProject;

// Source code for chapter 6 and 7 for the book:

// Writing an Interpreter in Object Pascal: Part 1


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
end;


procedure displayPrompt;
begin
  write ('>> ');
end;

// Tests:
// 5 - 1 - 2 = 2  left-right associativity
// 2^3^4 = 2417851639229258349412352 right-left associativity    ( 2.41785163922926E+0024)
// -2-4
// -2+5
// 2--3
// 2---3
// -2^4
// 8^(-1^(-8^7)) = 1/8
// 2---3^4


begin
  //Math.SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
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

