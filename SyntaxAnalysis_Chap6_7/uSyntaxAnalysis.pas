unit uSyntaxAnalysis;

interface

Uses Classes,SysUtils, uScanner;

type
   TSyntaxAnalysis = class (TObject)
         private
            sc : TScanner;
            procedure expect (thisToken : TTokenCode);
            procedure expression;
            procedure factor;
            procedure term;
            procedure assignment;
            procedure printExpression;
          public
            procedure myProgram;
            constructor Create (sc : TScanner);
   end;

implementation

constructor TSyntaxAnalysis.Create (sc : TScanner);
begin
  inherited Create;
  self.sc := sc;
end;


procedure TSyntaxAnalysis.expect (thisToken : TTokenCode);
begin
  if sc.token <> thisToken then
     raise Exception.Create('expecting: ' + sc.tokenToString (thisToken))
  else
     sc.nextToken;
end;


procedure TSyntaxAnalysis.expression;
begin
  term;
  while sc.token in [tPlus, tMinus] do
       begin
       sc.nextToken;
       term;
       end;
end;

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
     raise Exception.Create('expecting identifier, scalar or left parentheses');
  end;
end;

procedure TSyntaxAnalysis.term;
begin
  factor;
  while sc.token in [tMult, tDivide] do
       begin
       sc.nextToken;
       factor;
       end;
end;

procedure TSyntaxAnalysis.assignment;
begin
  expect (tIdentifier);
  expect (tEquals);
  expression;
end;


procedure TSyntaxAnalysis.printExpression;
begin
  sc.nextToken;
  expression;
end;


procedure TSyntaxAnalysis.myProgram;
begin
  sc.nextToken;
  case sc.token of
     tIdentifier : assignment;
     tPrint      : printExpression
  else
     raise Exception.Create('expecting assignment or print statement');
  end;
end;


end.
