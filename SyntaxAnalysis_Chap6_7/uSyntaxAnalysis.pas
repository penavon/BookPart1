unit uSyntaxAnalysis;

// Initial Syntax Parser  for Rhodus Verison One
// The code illustrates how to supprt basic expression parsing

// Developed under Delphi for Windows and Mac platforms.

// *** Ths source is distributed under Apache 2.0 ***

// Copyright (C) 2018 Herbert M Sauro

// Author Contact Information:
// email: hsauro@gmail.com

// Usage:
//
// sc := TScanner.Create;
// sc.scanString ('a = 2; b = a + 5.6')
// syntaxAnalyser := TSyntaxAnalysis.Create (sc);
// syntaxAnalyzer.myProgram;


interface

Uses Classes,SysUtils, uScanner;

type
   ESyntaxError = class (Exception);

   TSyntaxAnalysis = class (TObject)
         private
            sc : TScanner;
            procedure expect (expectedToken : TTokenCode);
            procedure expression;
            procedure factor;
            procedure term;
            procedure assignment;
            procedure printExpression;
          public
            procedure   myProgram;
            constructor Create (sc : TScanner);
   end;

implementation


constructor TSyntaxAnalysis.Create (sc : TScanner);
begin
  inherited Create;
  self.sc := sc;
end;


procedure TSyntaxAnalysis.expect (expectedToken : TTokenCode);
begin
  if sc.token = expectedToken then
     sc.nextToken
  else
     raise ESyntaxError.Create('expecting: ' + sc.tokenToString (expectedToken));
end;


// factor = integer | float | identifier | '(' expression ')'
procedure TSyntaxAnalysis.factor;
begin
  case sc.token of
     tInteger      : begin sc.nextToken; end;
     tFloat        : begin sc.nextToken; end;
     tIdentifier   : begin sc.nextToken; end;
     tLeftParenthesis :
         begin
         sc.nextToken;
         expression;
         expect (tRightParenthesis);
         end;
  else
     raise ESyntaxError.Create('expecting identifier, scalar or left parentheses');
  end;
end;


// term = factor { ('*', '\') factor }
procedure TSyntaxAnalysis.term;
begin
  factor;
  while sc.token in [tMult, tDivide] do
       begin
       sc.nextToken;
       factor;
       end;
end;

// term = term { ('+', '-') term }
procedure TSyntaxAnalysis.expression;
begin
  term;
  while sc.token in [tPlus, tMinus] do
       begin
       sc.nextToken;
       term;
       end;
end;

// assignment = identifier '=' expression
procedure TSyntaxAnalysis.assignment;
begin
  expect (tIdentifier);
  expect (tEquals);
  expression;
end;


// printExpression = expression
procedure TSyntaxAnalysis.printExpression;
begin
  sc.nextToken;
  expression;
end;

// myProgram = identifier | print
procedure TSyntaxAnalysis.myProgram;
begin
  sc.nextToken;
  case sc.token of
     tIdentifier : assignment;
     tPrint      : printExpression
  else
     raise ESyntaxError.Create('expecting assignment or print statement');
  end;
end;


end.
