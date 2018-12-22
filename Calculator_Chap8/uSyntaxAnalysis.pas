unit uSyntaxAnalysis;

// Syntax Parser for calculator project, Chapter 8

// Developed under Delphi for Windows and Mac platforms.

// *** Ths source is distributed under Apache 2.0 ***

// Copyright (C) 2018 Herbert M Sauro

// Author Contact Information:
// email: hsauro@gmail.com

interface

Uses Classes,SysUtils, uScanner, uSymbolTable;

type
   TSyntaxAnalysis = class (TObject)
         private
            sc : TScanner;
            function  getIdentifierValue (name : string) : double;
            procedure expect (thisToken : TTokenCode);
            function  factor : double;
            function  power : double;
            function  term : double;
            procedure assignment (variableName : string);
          public
            procedure   statement;
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


// Given the name of the symbol, return its value
// If the symbol cannot be found raise an exception.
function TSyntaxAnalysis.getIdentifierValue (name : string) : double;
begin
   sc.nextToken;
   if symbolTable.ContainsKey (name) then
      result := symbolTable.items[name]
   else
     raise ESyntaxException.Create('symbol: "' + name + '" has no assigned value');
end;


// factor = integer | float | identifier | '(' expression ')'
function TSyntaxAnalysis.factor : double;
begin
  case sc.token of
     tInteger      : begin sc.nextToken; result := sc.tokenInteger; end;
     tFloat        : begin sc.nextToken; result := sc.tokenFloat; end;
     tIdentifier   : result := getIdentifierValue (sc.tokenString);
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


// term = power { ( '*', '/') power }
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

// expression = term { ( '+', '0-') expression }
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


// assignment = expression
procedure TSyntaxAnalysis.assignment (variableName : string);
var value : double;
begin
  value := expression;
  if symbolTable.containsKey (variableName) then
     symbolTable.AddOrSetValue (variableName, value)
  else
     symbolTable.Add (variableName, value);
end;

// statement = assignment | expression
procedure TSyntaxAnalysis.statement;
var token1, token2 : TTokenRecord;
begin
  token1 := sc.tokenElement;
  sc.nextToken;
  token2 := sc.tokenElement;

  if sc.token = tEquals then
     begin
     if token1.FToken = tIdentifier then
        begin
        sc.nextToken;
        assignment (token1.FTokenString);
        end
     else
        raise ESyntaxException.Create('left-hand side of the assignment must be a variable');
     end
  else
     begin
     sc.pushBackToken(token1);
     sc.pushBackToken(token2);
     sc.nextToken;
     writeln (expression:10:6);
     end;
end;


end.
