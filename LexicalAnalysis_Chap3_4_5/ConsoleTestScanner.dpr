program ConsoleTestScanner;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  IoUtils,
  uScanner in 'uScanner.pas';

var inputStr : string;
    filename : string;
    fileContents : string;
    sc : TScanner;

begin
   if ParamCount = 1 then
      begin
      fileName := ParamStr (1);
      writeln ('Lexical analysis of file: ', fileName);
      writeln ('Test file contents:');
      writeln ('------------------------');
      try
         fileContents := TFile.ReadAllText(fileName);
      except
       on e: Exception do
          begin
          writeln (fileName, ': ', e.message);
          readln;
          exit;
          end;
      end;
      writeln (fileContents);
      writeln ('------------------------');

      sc := TScanner.create();
      try
        sc.scanString(fileContents);
        sc.nextToken;
        while sc.token <> tEndofStream do
            begin
            case sc.token of
                tIdentifier : writeln ('Identifier: ' + sc.tokenString);
                tInteger    : writeln ('Integer: ', sc.tokenInteger);
                tFloat      : writeln ('Float: ', floattostr (sc.tokenFloat));
                tString     : writeln ('String: "' + sc.tokenString + '"');
                tEquals     : writeln ('Equals');
                tEquivalence: writeln ('==');
                tFor        : writeln ('for');
                tTo         : writeln ('to');
                tIf         : writeln ('if');
                tThen       : writeln ('then');
                tFalse      : writeln ('False');
                tTrue       : writeln ('True');
                tEnd        : writeln ('end');
                tRepeat     : writeln ('repeat');
                tUntil      : writeln ('until');
                tPlus       : writeln ('plus');
                tMinus      : writeln ('minus');
                tMult       : writeln ('mult');
                tDivide     : writeln ('divide');
                tPower      : writeln ('power');
           tLeftParenthesis : writeln ('(');
          tRightParenthesis : writeln (')');
            end;
            sc.nextToken;
            end;
        writeln (sLineBreak + 'Success');
      except
         on e:Exception do
          writeln (e.message);
       end;
      end
   else
      writeln ('Execting file name');

   readln;
end.
