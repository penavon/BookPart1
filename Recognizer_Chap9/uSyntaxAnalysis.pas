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
// syntaxAnalyzer.mainProgram;

interface

Uses Classes, SysUtils, uScanner;

type
   TSyntaxAnalysis = class (TObject)
         private
            sc : TScanner;
            procedure expect (thisToken : TTokenCode);
            procedure  variable;
            procedure  doList;
            procedure  factor;
            procedure  power;
            procedure  term;
            procedure  simpleExpression;
            procedure  expression;
            procedure  statement;
            procedure  statementList;
            procedure  expressionList;
            procedure  assignment;
            procedure  ifStatement;
            procedure  ifEnd;
            procedure  whileStatement;
            procedure  repeatStatement;
            procedure  forStatement;
            procedure  functionDef;
            procedure  argumentList;
            procedure  argument;
            procedure  returnStmt;
            procedure  breakStmt;
            procedure  printlnStatement;
           public
            procedure    mainProgram;
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
     raise ESyntaxException.Create('expecting: ' + TScanner.tokenToString (thisToken))
  else
     sc.nextToken;
end;


procedure TSyntaxAnalysis.variable;
begin
  if sc.Token <> tIdentifier then
     raise ESyntaxException.Create('expecting identifier in function argument definition');
  sc.nextToken;
end;


procedure TSyntaxAnalysis.doList;
begin
  expression;
  while sc.token = tComma do
     begin
     sc.nextToken;
     expression;
     end;
end;

// factor = integer | float | '(' expression ')' | etc
procedure TSyntaxAnalysis.factor;
var ch : char;
begin
  case sc.token of
     tInteger      : sc.nextToken;
     tFloat        : sc.nextToken;
     tIdentifier   :
           begin
           sc.nextToken;
           case sc.token of
             tLeftParenthesis :
                begin
                sc.nextToken;
                if sc.token <> tRightParenthesis then
                   expressionList;
                expect (tRightParenthesis);
                end;
             tLeftBracket :
                begin
                sc.nextToken;
                expressionList;
                expect (tRightBracket);
                end;
           end
           end;
     tLeftParenthesis :
         begin
         sc.nextToken;
         expression;
         expect (tRightParenthesis);
         end;
     tLeftCurleyBracket :
         begin
         sc.nextToken;
         if sc.token <> tRightCurleyBracket then
            doList;
         expect (tRightCurleyBracket);
         end;
     tString :
         begin
         sc.nextToken;
         end;
     tNOT :
         begin
         sc.nextToken;
         expression;
         end;
     tFalse :
         begin
         sc.nextToken;
         end;
     tTrue :
         begin
         sc.nextToken;
         end
  else
     raise ESyntaxException.Create('expecting scalar, identifier or left parentheses');
  end;
end;


// power = {'+' | '-'} factor [ '^' power ]
procedure TSyntaxAnalysis.power;
begin
  // Handle unary operators
  while (sc.token = tMinus) or (sc.token = tPlus) do
     sc.nextToken;

  factor;
  if sc.token = tPower then
     begin
     sc.nextToken;
     power;
     end;
end;


// term = power { ('*', '/', MOD, AND, DIV) power }
procedure TSyntaxAnalysis.term;
begin
  power;
  while sc.token in [tMult, tDivide, tIDiv, tMod, tAnd] do
       begin
       if sc.token = tMult then
          begin
          sc.nextToken;
          factor;
          end
       else
          begin
          sc.nextToken;
          factor;
          end;
       end;
end;


// expression = term { ('+' | '-' | MOD | AND | DIV) power }
procedure TSyntaxAnalysis.simpleExpression;
begin
  term;
  while sc.token in [tPlus, tMinus, tOr, tXor] do
       begin
       if sc.token = tPlus then
          begin
          sc.nextToken;
          term;
          end
       else
          begin
          sc.nextToken;
          term;
          end;
       end;
end;


// expression = simpleExpression | simpleExpression relationalOp simpleExpression
procedure  TSyntaxAnalysis.expression;
begin
  simpleExpression;
  while sc.token in [tLessThan, tLessThanOrEqual, tMoreThan, tMoreThanOrEqual, tNotEqual, tEquivalence] do
     begin
     sc.nextToken;
     simpleExpression;
     end;
end;


// statement = assignment | forStatement | ifStatement
//                        | whileStatement | repeatStatement
//                        | returnStatment | breakStatement
//                        | function
procedure  TSyntaxAnalysis.statement;
begin
  case sc.token of
     tIdentifier : assignment;
     tIf         : ifStatement;
     tFor        : forStatement;
     tWhile      : whileStatement;
     tRepeat     : repeatStatement;
     tReturn     : returnStmt;
     tBreak      : breakStmt;
     tFunction   : functionDef;
     tPrintln    : printlnStatement;
    tEndOfStream : exit;
  else
     raise ESyntaxException.Create('expecting assignment, if, for, while, repeat, or function statement');
  end;
end;


// statementList = statement { ; statement }
procedure  TSyntaxAnalysis.statementList;
begin
   statement;
   while sc.token = tSemicolon do
      begin
      expect (tSemicolon);
      if sc.token in [tUntil, tEnd, tElse, tEndOfStream] then
         break;
      statement;
      end;
end;


procedure TSyntaxAnalysis.printlnStatement;
begin
  sc.nextToken;
  if sc.token = tLeftParenthesis then
     begin
     sc.nextToken;
     expressionList;
     expect (tRightParenthesis);
     end;
end;


// assignment = variable '=' expression
procedure  TSyntaxAnalysis.assignment;
begin
  expect (tIdentifier);
  if sc.token = tLeftBracket then
     begin
     sc.nextToken;
     expressionList;
     expect (tRightBracket);
     end;

  expect (tEquals);
  expression;
end;


// argumentList = expression { ',' expression }
procedure  TSyntaxAnalysis.expressionList;
begin
  expression;
  while sc.token = tComma do
      begin
      sc.nextToken;
      expression;
      end;
end;


// ifStatement = IF expression THEN statement ifEnd
procedure  TSyntaxAnalysis.ifStatement;
begin
  sc.nextToken;
  expression;
  expect (tThen);
  statementList;
  ifEnd;
end;


// ifEnd = END | ELSE statementList END
procedure  TSyntaxAnalysis.ifEnd;
begin
  if sc.token = tElse then
     begin
     sc.nextToken;
     statementList;
     expect (tEnd);
     end
  else
     expect (tEnd);
end;


// whileStatement = WHILE expression DO statementList END
procedure  TSyntaxAnalysis.whileStatement;
begin
  sc.nextToken;
  expression;
  expect (tDo);
  statementList;
  expect (tEnd);
end;


// repeatStatement = REPEAT statementList UNTIL expression
procedure  TSyntaxAnalysis.repeatStatement;
begin
  sc.nextToken;
  statementList;
  expect (tUntil);
  expression;
end;


// forStatement = FOR identifier = expression TO/DOWNTO expression DO statementList END
procedure  TSyntaxAnalysis.forStatement;
begin
  sc.nextToken;
  expect (tIdentifier);
  expect (tEquals);
  expression;
  if sc.token in [tTo, tDownTo] then
     begin
     expect (tTo);
     expression;
     expect (tDo);
     if sc.token = tEnd then
        raise ESyntaxException.Create('empty for loop');
     statementList;
     expect (tEnd);
     end
  else
     raise ESyntaxException.Create('expecting "to" or "downto" in for loop');
end;



// function = function identifier [ '(' argumentList ')' ]
procedure  TSyntaxAnalysis.functionDef;
begin
  sc.nextToken;
  expect (tIdentifier);
  if sc.token = tLeftParenthesis then
     begin
     sc.nextToken;
     argumentList;
     expect (tRightParenthesis);
     end;
  if sc.token = tEnd then
     raise ESyntaxException.Create('empty user defined function.');
  statementList;
  expect (tEnd);
end;


// argumentList = argument { ',' argument }
procedure  TSyntaxAnalysis.argumentList;
begin
  argument;
  while sc.token = tComma do
      begin
      sc.nextToken;
      argument;
      end;
end;


// argument = identifier | REF identifier
procedure  TSyntaxAnalysis.argument;
begin
  if sc.token = tRef then
     sc.nextToken;
  variable;
end;


// returnStatement = RETURN expression
procedure  TSyntaxAnalysis.returnStmt;
begin
  expect (tReturn);
  expression;
end;


procedure TSyntaxAnalysis.breakStmt;
begin
  sc.nextToken;
  expect (tSemicolon);
end;


// program = statementList
procedure  TSyntaxAnalysis.mainProgram;
begin
  statementList;
  if sc.token <> tEndofStream then
     expect (tSemicolon);
end;


end.
