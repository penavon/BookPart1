unit uSyntaxAnalysis;

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
            function  unaryTerm : double;
            function  term : double;
            procedure assignment (variableName : string);
          public
            procedure   statement;
            procedure   statement2;
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


function TSyntaxAnalysis.getIdentifierValue (name : string) : double;
begin
   sc.nextToken;
   if symbolTable.ContainsKey (name) then
      result := symbolTable.items[name]
   else
     raise ESyntaxException.Create('symbol: "' + name + '" has no assigned value');
end;


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


function TSyntaxAnalysis.unaryTerm : double;
var sign: TTokenCode;
begin
  result := power;
  exit;

  if (sc.token = tPlus) or (sc.token = tMinus) then
     begin
     sign := sc.token;
     sc.nextToken;
     if sign = tMinus then
        result := -power
     else
        result := power;
     end
  else
     result := power;
end;


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


procedure TSyntaxAnalysis.assignment (variableName : string);
var value : double;
begin
  value := expression;
  if symbolTable.containsKey (variableName) then
     symbolTable.AddOrSetValue (variableName, value)
  else
     symbolTable.Add (variableName, value);
end;


procedure TSyntaxAnalysis.statement;
var token1, token2 : TTokenElement;
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


procedure TSyntaxAnalysis.statement2;
var token1, token2 : TTokenElement;
begin
  sc.nextToken;
  if sc.token = tEquals then
     begin
     sc.nextToken;
     expression;
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
