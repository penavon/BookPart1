unit uSyntaxAnalysis;

// Syntax Parser for calculator project

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
// syntaxAnalyzer.expression;

interface

Uses Classes,SysUtils, uScanner;

type
   TSyntaxAnalysis = class (TObject)
         private
            sc : TScanner;
            procedure expect (thisToken : TTokenCode);
            function factor : double;
            function power : double;
            function term : double;
          public
            function    expression : double;
            constructor Create (sc : TScanner);
   end;

   ESyntaxException = class (Exception);

implementation

Uses Math;

constructor TSyntaxAnalysis.Create (sc : TScanner);
begin
  inherited Create;
  self.sc := sc;
end;


procedure TSyntaxAnalysis.expect (thisToken : TTokenCode);
begin
  if sc.token <> thisToken then
     raise ESyntaxException.Create('expecting: ' + sc.tokenToString (thisToken))
  else
     sc.nextToken;
end;


// factor = integer | float | '(' expression ')'
function TSyntaxAnalysis.factor : double;
begin
  case sc.token of
     tInteger      : begin sc.nextToken; result := sc.tokenInteger; end;
     tFloat        : begin sc.nextToken; result := sc.tokenFloat; end;
     tLeftParenthesis :
         begin
         sc.nextToken;
         result := expression;
         expect (tRightParenthesis);
         end;
  else
     raise ESyntaxException.Create('expecting scalar or left parentheses');
  end;
end;


// power = {'+' | '-'} factor [ '^' power ]
function TSyntaxAnalysis.power : double;
var sign : integer;
begin
  sign := 1;
  while (sc.token = tMinus) or (sc.token = tPlus) do
     begin
     if sc.token = tMinus then
        sign := -1*sign;
     sc.nextToken;
     end;

  result := factor;
  if sc.token = tPower then
     begin
     sc.nextToken;
     result := Math.Power (result, power);
     end;
  result := sign*result;
end;


// term = power { ('*', '/') power }
function TSyntaxAnalysis.term : double;
begin
  result := power;
  while sc.token in [tMult, tDivide] do
       begin
       if sc.token = tMult then
          begin
          sc.nextToken;
          result := result * power
          end
       else
          begin
          sc.nextToken;
          result := result / power;
          end;
       end;
end;


// expression = term { ('+', '-') power }
function TSyntaxAnalysis.expression : double;
begin
  result := term;
  while sc.token in [tPlus, tMinus] do
       begin
       if sc.token = tPlus then
          begin
          sc.nextToken;
          result := result + term;
          end
       else
          begin
          sc.nextToken;
          result := result - term;
          end;
       end;
end;

end.
