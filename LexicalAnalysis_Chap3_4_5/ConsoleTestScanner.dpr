program ConsoleTestScanner;

// *** Ths source is distributed under Apache 2.0 ***

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

procedure writeIdentifier (tokenStr : string; tr : TTokenRecord);
begin
  writeln (Format ('%-12s %-14s %-7d %-7d', ['Identifier:', tokenStr, tr.lineNumber, tr.columnNumber]));
end;

procedure writeKeyword (tokenStr: string; tr : TTokenRecord);
begin
  writeln (Format ('%-12s %-14s %-7d %-7d', ['Keyword:', tokenStr, tr.lineNumber, tr.columnNumber]));
end;

procedure writeSymbol (tokenStr: string; tr : TTokenRecord);
begin
  writeln (Format ('%-12s %-14s %-7d %0-7d', ['Symbol:', tokenStr, tr.lineNumber, tr.columnNumber]));
end;

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

      sc := TScanner.create();
      try
        sc.scanString(fileContents);
        sc.nextToken;
        writeln (Format ('%-12s %-14s %-7s %-7s', ['Type', 'Value', 'Line #', 'Column #']));
        writeln ('--------------------------------------------');
        while sc.token <> tEndofStream do
            begin
            case sc.token of
                tIdentifier : writeIdentifier (sc.tokenString, sc.tokenRecord);
                tInteger    : writeln (Format ('%-12s %-14d %-7d %-7d', ['Integer:', sc.tokenInteger, sc.tokenRecord.lineNumber, sc.tokenRecord.columnNumber]));
                tFloat      : writeln (Format ('%-12s %-14g %-7d %-7d', ['Double:', sc.tokenFloat, sc.tokenRecord.lineNumber, sc.tokenRecord.columnNumber]));
                tString     : writeln (Format ('%-12s %-14s %-7d %-7d', ['String:', sc.tokenString, sc.tokenRecord.lineNumber, sc.tokenRecord.columnNumber]));
                tEquals     : writeSymbol  ('=', sc.tokenRecord);
                tEquivalence: writeSymbol  ('==', sc.tokenRecord);
                tFor        : writeKeyword ('for', sc.tokenRecord);
                tTo         : writeKeyword ('to', sc.tokenRecord);
                tIf         : writeKeyword ('if', sc.tokenRecord);
                tThen       : writeKeyword ('then', sc.tokenRecord);
                tFalse      : writeKeyword ('False', sc.tokenRecord);
                tTrue       : writeKeyword ('True', sc.tokenRecord);
                tEnd        : writeKeyword ('end', sc.tokenRecord);
                tRepeat     : writeKeyword ('repeat', sc.tokenRecord);
                tUntil      : writeKeyword ('until', sc.tokenRecord);
                tPlus       : writeSymbol  ('plus', sc.tokenRecord);
                tMinus      : writeSymbol  ('minus', sc.tokenRecord);
                tMult       : writeSymbol  ('mult', sc.tokenRecord);
                tDivide     : writeSymbol  ('divide', sc.tokenRecord);
                tPower      : writeSymbol  ('power', sc.tokenRecord);
           tLeftParenthesis : writeSymbol  ('(', sc.tokenRecord);
          tRightParenthesis : writeSymbol  (')', sc.tokenRecord);
            end;
            sc.nextToken;
            end;
        writeln ('--------------------------------------------');
        writeln ('Success');
      except
         on e:Exception do
          writeln (e.message);
       end;
      end
   else
      writeln ('Execting file name');

   readln;
end.
