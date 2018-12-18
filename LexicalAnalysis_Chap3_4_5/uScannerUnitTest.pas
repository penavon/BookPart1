unit uScannerUnitTest;

// Uncovered bugs:
// Can't parse .5
// Doesn't detect CRCR, or CR
interface

uses
  DUnitX.TestFramework, uScanner;

type

  [TestFixture]
  TScannerTest = class(TObject)
  private
    sc : TScanner;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test] // Key words
    [TestCase ('TestKeyWord1', 'end,tEnd')]
    [TestCase ('TestKeyWord2', 'while,tWhile')]
    [TestCase ('TestKeyWord3', 'do,tDo')]
    [TestCase ('TestKeyWord4', 'repeat,tRepeat')]
    [TestCase ('TestKeyWord5', 'until,tUntil')]
    [TestCase ('TestKeyWord6', 'if,tIf')]
    [TestCase ('TestKeyWord7', 'then,tThen')]
    [TestCase ('TestKeyWord8', 'True,tTrue')]
    [TestCase ('TestKeyWord9', 'False,tFalse')]
    [TestCase ('TestKeyWord10', '=,tEquals')]
    [TestCase ('TestKeyWord11', '>,tMoreThan')]
    [TestCase ('TestKeyWord12', '>=,tMoreThanOrEqual')]
    [TestCase ('TestKeyWord13', '<,tLessThan')]
    [TestCase ('TestKeyWord14', '<=,tLessThanOrEqual')]
    [TestCase ('TestKeyWord15', '!=,tNotEqual')]
    [TestCase ('TestKeyWord16', '(,tLeftParenthesis')]
    [TestCase ('TestKeyWord17', '),tRightParenthesis')]
    [TestCase ('TestKeyWord18', '[,tLeftBracket')]
    [TestCase ('TestKeyWord19', '],tRightBracket')]
    [TestCase ('TestKeyWord20', '{,tLeftCurleyBracket')]
    [TestCase ('TestKeyWord21', '},tRightCurleyBracket')]
    [TestCase ('TestKeyWord22', '+,tPlus')]
    [TestCase ('TestKeyWord23', '-,tMinus')]
    [TestCase ('TestKeyWord24', '*,tMult')]
    [TestCase ('TestKeyWord25', '/,tDivide')]
    [TestCase ('TestKeyWord26', '^,tPower')]
    [TestCase ('TestKeyWord27', 'and,tAnd')]
    [TestCase ('TestKeyWord28', 'or,tOr')]
    [TestCase ('TestKeyWord27', 'not,tNOt')]
    [TestCase ('TestKeyWord28', 'xor,tXor')]
    procedure TestSymbolRecognition (inputString : string; expectedToken : TTokenCode);

    [Test] // Word
    [TestCase ('TestIdent1',  'ident,ident,tIdentifier')]
    [TestCase ('TestIdent2',  '_ident,_ident,tIdentifier')]
    [TestCase ('TestIdent3',  '_ident99,_ident99,tIdentifier')]
    [TestCase ('TestIdent3',  '_id_ent99,_id_ent99,tIdentifier')]
    procedure TestIdentifierScanning (Value1 : string; Value2 : string; Value3 : TTokenCode);

    [Test] // String
    [TestCase ('TestString',  '"string",string,tString')]
    [TestCase ('TestString',  '"",,tString')]
    procedure TestStringScanning (Value1 : string; Value2 : string; Value3 : TTokenCode);

    [Test] // Tesing Escape Characters
    procedure TestStringEscapeCharacters_Newline;
    [Test]
    procedure TestStringEscapeCharacters_CR;
    [Test]
    procedure TestStringEscapeCharacters_TAB;

    [Test] // Integer values
    [TestCase ('TestInteger1', '25,25,tInteger')]
    [TestCase ('TestInteger2', '0,0,tInteger')]
    [TestCase ('TestInteger3', '0123,123,tInteger')]
    procedure TestIntegerScanning (Value1 : string; Value2 : integer; Value3 : TTokenCode);

    [Test]  // Integer Overflow
    procedure TestIntOverflow;

    [Test] // Floating point numbers
    [TestCase ('TestFloat1', '3.1415,3.1415,tFloat')]
    [TestCase ('TestFloat2', '0.1415,0.1415,tFloat')]
    [TestCase ('TestFloat3', '.5,0.5,tFloat')]
    [TestCase ('TestFloat4', '1E-1,0.1,tFloat')]
    [TestCase ('TestFloat5', '1E+1,10,tFloat')]
    [TestCase ('TestFloat6', '1E-3,0.001,tFloat')]
    [TestCase ('TestFloat6', '1.234E-3,0.001234,tFloat')]
    [TestCase ('TestFloat7', '0.234E-3,0.000234,tFloat')]
    procedure TestFloatingPoint (Value1 : string; Value2 : double; Value3 : TTokenCode);

    [Test]
    procedure TestMissingExponent;
    [Test]
    procedure TestExponentOverflow;
    [Test]
    procedure TestExponentPeriod;

    [Test] // Filter CRLF
    [TestCase ('TestCRLF1', 'before'+sLineBreak+'after,before,after')]
    [TestCase ('TestCRLF2', 'before'+#10+'after,before,after')]
    [TestCase ('TestCRLF3', 'before'+#10#10+'after,before,after')]
    [TestCase ('TestCRLF4', 'before'+#10#10#10+'after,before,after')]
    procedure TestCRLF (Value1 : string; Value2, Value3 : string);

    [Test] // Filter CRLF Exception Test, CR on its own
    [TestCase ('TestCRLFExc', 'before'+#13+'after')]
    procedure TestCRLFException1 (Value1 : string);

    [Test] // Filter CRLF Exception Test, multiple CFs
    [TestCase ('TestCRLFExc', 'before'+#13#13+'after')]
    procedure TestCRLFException2 (Value1 : string);

    [Test] // Filter CRLF Exception Test, multiple CFs
    [TestCase ('TestCRLFExc', 'before'+#13#13#13+'after')]
    procedure TestCRLFException3 (Value1 : string);

    // Test sequence of tokens
    [Test]
    procedure TestSequenceOfTokens;

    [Test] // Use of \t in strings
    procedure TestTabKeyInString;

    [Test] // Use of \n\n in string
    procedure TestTwoNewlinesInString;

    [Test] //  Comment test: // Comment [No newline]
    procedure TestOneLineCommentWithoutNewLine;

    [Test]   // Comment test: // Comment [With newline]
    procedure TestOneLineComment;

    [Test]   // Comment test: /* Comment */
    procedure TestMultiLineCommentOnSameLine;

    [Test]   // Comment test: /* Comment [newline] Comment */
    procedure TestMultiLineCommentOnMultipleLines;

    [Test]   // Test for illegal characeter exception
    procedure TestIllegalCharacter;

    [Test]   // Test for MALFORMED !=
    procedure TestNotEqualsToError;
  end;

implementation

USes Rtti;

const
  TAB = #09;     // TAB key
  LF  = #10;     // Line feed character
  CR  = #13;     // Carriage return character


procedure TScannerTest.Setup;
begin
  sc := TScanner.create;
end;

procedure TScannerTest.TearDown;
begin
  sc.Free;
end;

procedure TScannerTest.TestSymbolRecognition (inputString : string;  expectedToken : TTokenCode);
begin
  sc.scanString(inputString);
  sc.nextToken;
  Assert.AreEqual (sc.token, expectedToken);
end;


procedure TScannerTest.TestIdentifierScanning (Value1 : string; Value2 : string; Value3 : TTokenCode);
begin
  sc.scanString(Value1);
  sc.nextToken;
  Assert.AreEqual (sc.token, Value3);
  Assert.AreEqual (sc.tokenString, Value2);
end;


procedure TScannerTest.TestStringScanning (Value1 : string; Value2 : string; Value3 : TTokenCode);
begin
  sc.scanString(Value1);
  sc.nextToken;
  Assert.AreEqual (sc.tokenString, Value2);
  Assert.AreEqual (sc.token, Value3);
end;

procedure TScannerTest.TestStringEscapeCharacters_Newline;
begin
  sc.scanString('"before\nafter"');
  sc.nextToken;
  Assert.AreEqual (sc.tokenString, 'before'+sLineBreak+'after');
end;

procedure TScannerTest.TestStringEscapeCharacters_CR;
begin
  sc.scanString('"before\rafter"');
  sc.nextToken;
  Assert.AreEqual (sc.tokenString, 'before'+CR+'after');
end;

procedure TScannerTest.TestStringEscapeCharacters_TAB;
begin
  sc.scanString('"before\tafter"');
  sc.nextToken;
  Assert.AreEqual (sc.tokenString, 'before'+TAB+'after');
end;

procedure TScannerTest.TestIntegerScanning (Value1 : string; Value2 : integer; Value3 : TTokenCode);
begin
  sc.scanString(Value1);
  sc.nextToken;
  Assert.AreEqual (sc.token, Value3);
  Assert.AreEqual (sc.tokenInteger, Value2);
end;


procedure TScannerTest.TestMissingExponent;
begin
  sc.scanString ('1E');
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Value on Exponent Missing Error Raised');
end;


procedure TScannerTest.TestExponentOverflow;
begin
  sc.scanString('1.234E87654');
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Exponent Overflow Raised');
end;


procedure TScannerTest.TestExponentPeriod;
begin
  sc.scanString('.');
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Single Period Error Raised');
end;


procedure TScannerTest.TestIntOverflow;
begin
  sc.scanString('2147483648');
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Int Overflow Raised');
end;


procedure TScannerTest.TestFloatingPoint (Value1 : string; Value2 : double; Value3 : TTokenCode);
begin
  sc.scanString(Value1);
  sc.nextToken;
  Assert.AreEqual (sc.token, Value3);
  Assert.AreEqual (sc.tokenFloat, Value2);
end;


procedure TScannerTest.TestCRLF (Value1 : string; Value2, Value3 : string);
begin
  sc.scanString(Value1);
  sc.nextToken;
  Assert.AreEqual(sc.tokenString, Value2);
  sc.nextToken;
  Assert.AreEqual(sc.tokenString, Value3);
 end;


procedure TScannerTest.TestCRLFException1 (Value1 : string);
begin
  sc.scanString(Value1);
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'A CR on its own is illegal');
 end;

procedure TScannerTest.TestCRLFException2 (Value1 : string);
begin
  sc.scanString(Value1);
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Two CRs in a row, illegal');
 end;

procedure TScannerTest.TestCRLFException3 (Value1 : string);
begin
  sc.scanString(Value1);
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Three CRs in a row, illegal');
 end;


procedure TScannerTest.TestSequenceOfTokens;
begin
  sc.scanString('if while do end repeat (){}^-+/ * > >= < <= == != "string" 25 3.14');
  sc.nextToken; Assert.AreEqual(sc.token, tIf);
  sc.nextToken; Assert.AreEqual(sc.token, tWhile);
  sc.nextToken; Assert.AreEqual(sc.token, tDo);
  sc.nextToken; Assert.AreEqual(sc.token, tEnd);
  sc.nextToken; Assert.AreEqual(sc.token, tRepeat);
  sc.nextToken; Assert.AreEqual(sc.token, tLeftParenthesis);
  sc.nextToken; Assert.AreEqual(sc.token, tRightParenthesis);
  sc.nextToken; Assert.AreEqual(sc.token, tLeftCurleyBracket);
  sc.nextToken; Assert.AreEqual(sc.token, tRightCurleyBracket);
  sc.nextToken; Assert.AreEqual(sc.token, tPower);
  sc.nextToken; Assert.AreEqual(sc.token, tMinus);
  sc.nextToken; Assert.AreEqual(sc.token, tPlus);
  sc.nextToken; Assert.AreEqual(sc.token, tDivide);
  sc.nextToken; Assert.AreEqual(sc.token, tMult);
  sc.nextToken; Assert.AreEqual(sc.token, tMoreThan);
  sc.nextToken; Assert.AreEqual(sc.token, tMoreThanOrEqual);
  sc.nextToken; Assert.AreEqual(sc.token, tLessThan);
  sc.nextToken; Assert.AreEqual(sc.token, tLessThanOrEqual);
  sc.nextToken; Assert.AreEqual(sc.token, tEquivalence);
  sc.nextToken; Assert.AreEqual(sc.token, tNotEqual);
  sc.nextToken; Assert.AreEqual(sc.token, tString);
  sc.nextToken; Assert.AreEqual(sc.token, tInteger);
  sc.nextToken; Assert.AreEqual(sc.token, tFloat);
end;

procedure TScannerTest.TestTabKeyInString;
begin
  sc.scanString('"string\t"');
  sc.nextToken; Assert.AreEqual(sc.token, tString);
  Assert.AreEqual(sc.tokenString, 'string'#9);
end;

procedure TScannerTest.TestTwoNewlinesInString;
begin
  sc.scanString('"before\n\nafter"');
  sc.nextToken; Assert.AreEqual(sc.token, tString);
  Assert.AreEqual(sc.tokenString, 'before'#13#10#13#10'after');
end;


procedure TScannerTest.TestOneLineCommentWithoutNewLine;
begin
  sc.scanString('// A comment');
  sc.nextToken;
  Assert.AreEqual(sc.token, tEndofStream);
end;

procedure TScannerTest.TestOneLineComment;
begin
  sc.scanString('// A comment'#13#10);
  sc.nextToken;
  Assert.AreEqual(sc.token, tEndofStream);
end;


procedure TScannerTest.TestMultiLineCommentOnSameLine;
begin
  sc.scanString('/* A comment */');
  sc.nextToken;
  Assert.AreEqual(sc.token, tEndofStream);
end;


procedure TScannerTest.TestMultiLineCommentOnMultipleLines;
begin
  sc.scanString('/* Comment'#13#10'Comment */');
  sc.nextToken;
  Assert.AreEqual(sc.token, tEndofStream);
end;

procedure TScannerTest.TestIllegalCharacter;
begin
  sc.scanString('$');
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Illegal Character');
end;

procedure TScannerTest.TestNotEqualsToError;
begin
  sc.scanString('!x');
  Assert.WillRaise(procedure begin sc.nextToken; end, EScannerError, 'Expecting = after !');
end;

initialization
  TDUnitX.RegisterTestFixture(TScannerTest);
end.
