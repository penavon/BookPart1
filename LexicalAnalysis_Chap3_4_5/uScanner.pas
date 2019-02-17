unit uScanner;

// ------------------------------------------------------------------------
// TScanner - general purpose tokeniser
// Originally Written 11 Feb 1998 (HMS)
// This version heavily modified: 15 Nov, 2018
// ------------------------------------------------------------------------

// Developed under Delphi for Windows and Mac platforms.

// *** Ths source is distributed under Apache 2.0 ***

// Copyright (C) 1998-2018 Herbert M Sauro

// Author Contact Information:
// email: hsauro@gmail.com

{  Usage:

   p := TScanner.Create;
   p.scanString (str);
   p.nextToken;   // Fetch first token
   if p.Token = tPlus then ......

   p.free;

   If an identifier or a string is scanned then the value can be found in
   p.TokenString.

   If an integer or float is scanned then the value can be found in
   p.TokenInteger or p.TokenFloat respectively

   Identifiers are allowed to have underscores, eg Start_Now

   Blanks are ignored and comments can be embeded in the test and are of the form:

   // a comment
   #  .....;
   /* another comment
      another line in the comment
   */
}

interface

uses Windows, SysUtils, Classes, Generics.Collections;

type
  { ********************* Lexical scanner types etc *********************** }
  EScannerError = class (Exception);

  // List of tokens supported in Version one of Rhodus
  TTokenCode = (tEndofStream,
                tIdentifier,
                tFloat,
                tInteger,
                tString,
                tPlus,
                tMinus,
                tMult,
                tDivide,
                tPower,
                tDiv,
                tMod,
                tLessThan,
                tLessThanOrEqual,
                tMoreThan,
                tMoreThanOrEqual,
                tNotEqual,
                tRightParenthesis,
                tLeftParenthesis,
                tLeftBracket,
                tRightBracket,
                tLeftCurleyBracket,
                tRightCurleyBracket,
                tEquals,
                tEquivalence,
                tApostrophy,
                tDollar,
                tSemicolon,
                tColon,
                tComma,
                tAnd,
                tOr,
                tNot,
                tXor,
                tEnd,
                tIf,
                tThen,
                tElse,
                tFalse,
                tTrue,
                tFor,
                tDo,
                tTo,
                tDownTo,
                tWhile,
                tRepeat,
                tUntil,
                tOf,
                tBreak,
                tFunction,

                tPrint);  // tPrint is a token used for testing

  // Information on a single token
  TTokenRecord = record
                    lineNumber, columnNumber : integer;
                    FToken        : TTokenCode;
                    FTokenString  : string;
                    FTokenFloat   : double;
                    FTokenInteger : Integer;
                  end;

  TScanner = class (TObject)
            private
               InMultiLineComment : Boolean;

               FTokenRecord : TTokenRecord;
               // The current character read from the stream
               Fch : Char;

               FKeyWordList : TStringList;
               FLineNumber : integer;
               FColumnNumber : integer;
               FStreamReader : TStreamReader;

               procedure startScanner;
               procedure skipBlanksAndComments;
               procedure skipSingleLineComment;
               procedure skipMultiLIneComment;
               function  isLetter (ch : Char) : boolean;
               function  isDigit (ch : Char) : boolean;
               procedure getWord;
               procedure getString;
               procedure getNumber;
               procedure getSpecial;
               procedure addKeyWords;
               function  isKeyWord (const FTokenString : string; var Token : TTokenCode) : boolean;

               function getTokenCode : TTokenCode;
               function getTokenString : string;
               function getTokenInteger : integer;
               function getTokenDouble : double;

               function  readRawChar : Char;
               function  getOS_IndependentChar : Char;
               function  nextChar : Char;
             public
               constructor create;
               destructor  destroy; override;

               procedure nextToken;

               // Debuggin functions
               function  tokenToString : string; overload;
               function  tokenToString (tokenCode : TTokenCode) : string; overload;
               function  tokenLiteral : string;

               procedure scanString (const str : string);
               procedure scanFile (const Filename : string);
               // Returns token value whether its an integer or double
               function  getScalar : double;
               property  tokenRecord : TTokenRecord read FTokenRecord;
               property  token : TTokenCode read getTokenCode;
               property  tokenString : string read getTokenString;
               property  tokenInteger : integer read getTokenInteger;
               property  tokenFloat : double read getTokenDouble;
            end;


implementation

Uses Math;

const
  MAX_DIGIT_COUNT  = 3; // Max # of digits in exponent of floating point number
  MAX_EXPONENT = 308;   // Maximum size of exponent in sceintific notation
  TAB = #09;            // TAB key
  LF = #10;             // Line feed character
  CR = #13;             // Carriage return character
  EOF_CHAR = Char ($FF);// Defines end of string/file marker


constructor TScanner.Create;
begin
  inherited Create;
  addKeyWords;
 end;


destructor TScanner.Destroy;
begin
  FKeyWordList.Free;
  freeAndNil(FStreamReader); // yyReader owns stream so stream will be freeed too.
  inherited Destroy;
end;


procedure TScanner.scanString (const str : string);
begin
  freeAndNil(FStreamReader);
  // Use a reader because we'll have access to peek and endOfStream
  FStreamReader := TStreamReader.Create(TStringStream.Create (str, TEncoding.UTF8));
  FStreamReader.OwnStream;
  startScanner;
end;


procedure TScanner.scanFile (const filename : string);
begin
  freeAndNil (FStreamReader);
  FStreamReader := TStreamReader.Create(TBufferedFileStream.Create (filename, fmOpenRead), TEncoding.UTF8);
  FStreamReader.OwnStream;
  startScanner;
end;


procedure TScanner.startScanner;
begin
  FLineNumber := 1;
  FColumnNumber := 0;
  Fch := nextChar;
end;


// Helper routines
function TScanner.getTokenCode : TTokenCode;
begin
  result := FTokenRecord.FToken;
end;

function TScanner.getTokenString: string;
begin
  result := FTokenRecord.FTokenString;
end;

function TScanner.getTokenInteger : integer;
begin
  result := FTokenRecord.FTokenInteger;
end;

function TScanner.getTokenDouble: double;
begin
  result := FTokenRecord.FTokenFloat;
end;


// Add the Rhodus supported keywords here
// Could be refactored to use a TDictionary
procedure TScanner.addKeyWords;
begin
  FKeyWordList := TStringList.Create;
  FKeyWordList.Sorted := True;

  FKeyWordList.AddObject ('if', TObject (tIf));
  FKeyWordList.AddObject ('do', TObject (tDo));
  FKeyWordList.AddObject ('to', TObject (tTo));
  FKeyWordList.AddObject ('or', TObject (tOr));
  FKeyWordList.AddObject ('of', TObject (tOf));

  FKeyWordList.AddObject ('end', TObject (tEnd));
  FKeyWordList.AddObject ('for', TObject (tFor));
  FKeyWordList.AddObject ('and', TObject (tAnd));
  FKeyWordList.AddObject ('xor', TObject (tXor));
  FKeyWordList.AddObject ('not', TObject (tNot));
  FKeyWordList.AddObject ('div', TObject (tDiv));
  FKeyWordList.AddObject ('mod', TObject (tMod));

  FKeyWordList.AddObject ('then', TObject (tThen));
  FKeyWordList.AddObject ('else', TObject (tElse));
  FKeyWordList.AddObject ('True', TObject (tTrue));
  FKeyWordList.AddObject ('False', TObject (tFalse));

  FKeyWordList.AddObject ('while', TObject (tWhile));
  FKeyWordList.AddObject ('until', TObject (tUntil));
  FKeyWordList.AddObject ('break', TObject (tBreak));

  FKeyWordList.AddObject ('repeat', TObject (tRepeat));
  FKeyWordList.AddObject ('downto', TObject (tDownTo));

  FKeyWordList.AddObject ('function', TObject (tFunction));

  FKeyWordList.AddObject ('print', TObject (tPrint));

  FKeyWordList.Sort;
end;


// If a keyword is found, it returns the corresponding token in argument Token
function TScanner.isKeyWord (const FTokenString : string; var Token : TTokenCode) : boolean;
var index : integer;
begin
  result := False;
  if FKeyWordList.Find(FTokenString, index) then
     begin
     Token := TTokenCode (FKeyWordList.Objects[Index]);
     exit (True);
     end;
end;

// get a single char from the input stream
function TScanner.readRawChar : Char;
begin
  if FStreamReader = nil then
     exit (char (EOF_CHAR));

  if FStreamReader.EndOfStream  then
     begin
     FreeAndNil (FStreamReader);
     result := char (EOF_CHAR);
     end
  else
     begin
     inc (FColumnNumber);
     result := Char (FStreamReader.Read);
     end;
end;


// get a single char from the readRawCjar and convert any CRLF to LF
function TScanner.getOS_IndependentChar : Char;
begin
  Fch:= readRawChar;
  if (Fch = CR) or (Fch = LF) then
     begin
     if Fch = CR then
        begin
        Fch := readRawChar;
        if Fch = LF then
           result := Fch
        else
           raise EScannerError.Create ('expecting line feed character');
        end
     else
        result := FCh;
     end
  else
     result := FCh;
end;


// Update Fch to the next character in input stream, filter out LF
function TScanner.nextChar : Char;
begin
  result := getOS_IndependentChar;
  // Ignore LF and return the next character
  if result = LF then
        begin
        inc (FLineNumber);
        FColumnNumber := 0;
        result := ' ';
        end;
end;


// Deal with this kind of comment  /* ..... */
procedure TScanner.skipMultiLineComment;
begin
  InMultiLineComment := True;
  // Move past '*'
  Fch := nextChar;
  while True do
     begin
     while (Fch <> '*') and (Fch <> EOF_CHAR) do
        FCh := nextChar;
     if FCh = EOF_CHAR then
        exit;

     FCh := nextChar;
     if FCh = '/' then
        begin
        Fch := nextChar;
        InMultiLineComment := False;
        break;
        end;
     end;
end;

// Deal with this kind of comment  // ......
procedure TScanner.skipSingleLineComment;
begin
  while (Fch <> LF) and (FCh <> EOF_CHAR) do
        Fch := getOS_IndependentChar;
  if FCh <> EOF_CHAR then
     Fch := nextChar;
end;


// Skip blanks, tabs and comments
procedure TScanner.skipBlanksAndComments;
begin
  while Fch in [' ', TAB, '/']  do
        begin
        if (Fch in [' ', TAB])  then
           Fch := nextChar
        else
           begin
           // Check for start of comment
           if (char (FStreamReader.Peek) = '/') or (char (FStreamReader.Peek) = '*') then
              begin
              Fch := getOS_IndependentChar;
              if Fch = '/' then // This kind of comment  // abc - single line
                 skipSingleLineComment
              else if Fch = '*' then // This kind of comment: /* abc */ - multiline
                 skipMultiLineComment;
              end
           else
              break;
           end;
        end;
end;


// Scan in a number token, can distinguish between integer and float
// (including scientific notation) Valid numbers include:
// 23, 1.2, 0.3, .1234345, 1e3, 1e-6, 3.45667E-12
// Note: negative numbers not supported here, instead the '-' sign is read
// in as a separate token in its own right, therefore -1.2 yields two
// tokens when scanned, tMinus followed by tFloat. It was done this way so that
// unary minuses in things such as "-(1.2)" can be handled by the parser
procedure TScanner.getNumber;
var singleDigit : integer; scale : double;
    evalue : integer;
    exponentSign : integer;
    hasLeftHandSide, hasRightHandSide : boolean;
begin
  FTokenRecord.FTokenInteger := 0; FTokenRecord.FTokenFloat := 0.0;
  hasLeftHandSide := False; hasRightHandSide := False;

  // Assume it's an integer
  FTokenRecord.FToken := tINTEGER;
  // check for decimal point just in case user has typed something like .5
  if Fch <> '.' then
     begin
     hasLeftHandSide := True;
     repeat
       singleDigit := ord (Fch) - ord ('0');
       if FTokenRecord.FTokenInteger <= (MaxInt - singleDigit) div 10 then
          begin
          FTokenRecord.FTokenInteger := 10*FTokenRecord.FTokenInteger + singleDigit;
          Fch := nextchar;
          end
       else
         raise EScannerError.Create ('integer overflow, constant value too large to read');
     until not isDigit (FCh);
     end;

  scale := 1;
  if Fch = '.' then
     begin
     // Then it's a float. Start collecting fractional part
     FTokenRecord.FToken := tFLOAT; FTokenRecord.FTokenFloat := FTokenRecord.FTokenInteger;
     Fch := nextchar;
     if isDigit (FCh) then hasRightHandSide := True;

     while isDigit (FCh) do
        begin
        scale := scale * 0.1;
        singleDigit := ord (Fch) - ord ('0');
        FTokenRecord.FTokenFloat := FTokenRecord.FTokenFloat + (singleDigit * scale);
        Fch := nextchar;
        end;
     end;

  // Check there is actually a number
  if (hasLeftHandSide = False) and (hasRightHandSide = False) then
     raise EScannerError.Create ('single period on its own is not a valid number');

   exponentSign := 1;
  // Next check for scientific notation
  if (Fch = 'e') or (Fch = 'E') then
     begin
     // Then it's a float. Start collecting exponent part
     if FTokenRecord.FToken = tInteger then
        begin
        FTokenRecord.FToken := tFLOAT;
        FTokenRecord.FTokenFloat := FTokenRecord.FTokenInteger;
        end;
     Fch := nextchar;
     if (Fch = '-') or (Fch = '+') then
        begin
        if Fch = '-' then exponentSign := -1;
        Fch := nextchar;
        end;
     { accumulate exponent, check that first ch is a digit }
     if not isDigit (Fch) then
        raise EScannerError.Create ('syntax error: number expected in exponent');


     evalue := 0;
     repeat
       singleDigit := ord (Fch) - ord ('0');
       if evalue <= (MAX_EXPONENT - singleDigit) div 10 then
          begin
          evalue := 10*evalue + singleDigit;
          Fch := nextchar;
          end
       else
         raise EScannerError.Create ('exponent overflow, maximum value for exponent is ' + inttostr (MAX_EXPONENT));
     until not isDigit (FCh);

     evalue := evalue * exponentSign;
     if token = tInteger then
        FTokenRecord.FTokenFloat := FTokenRecord.FTokenInteger * Math.IntPower (10, evalue)
     else
        FTokenRecord.FTokenFloat := FTokenRecord.FTokenFloat * Math.Power (10.0, evalue);
     end;
end;


// Help routines to get an value whether its an integer or double.
function TScanner.getScalar : double;
begin
  result := 0.0;
  if (FTokenRecord.FToken = tInteger) then
     result := FTokenRecord.FTokenInteger;
  if (FTokenRecord.FToken = tFloat) then
     result := FTokenRecord.FTokenFloat;
end;


function TScanner.isLetter (ch : Char) : boolean;
begin
  result :=  ch in ['a'..'z', 'A'..'Z', '_'];
end;


function TScanner.isDigit (ch : Char) : boolean;
begin
  result:= ch in ['0'..'9'];
end;


// Scan in an identifier token
procedure TScanner.getWord;
begin
  FTokenRecord.FTokenString := '';

  while isLetter (Fch) or isDigit (Fch) do
        begin
        FTokenRecord.FTokenString := FTokenRecord.FTokenString + Fch;  // Inefficient but convenient
        Fch := nextchar;
        end;

  // Check if word is a keyword
  if not IsKeyWord (FTokenRecord.FTokenString, FTokenRecord.FToken) then
     FTokenRecord.FToken := tIdentifier;
end;



// Get a token of the form "A string"
procedure TScanner.getString;
begin
  FTokenRecord.FTokenString := '';
  FTokenRecord.FToken := tString;

  Fch := nextChar;
  while Fch <> EOF_CHAR do
        begin
        if Fch = '\' then
           begin
           Fch := nextChar;
           case Fch of
               '\' : FTokenRecord.FTokenString := FTokenRecord.FTokenString + '\';
               'n' : FTokenRecord.FTokenString := FTokenRecord.FTokenString + sLineBreak;
               'r' : FTokenRecord.FTokenString := FTokenRecord.FTokenString + CR;
               't' : FTokenRecord.FTokenString := FTokenRecord.FTokenString + TAB;
            else
               FTokenRecord.FTokenString := FTokenRecord.FTokenString + '\' + Fch;
            end;
            Fch := nextChar;
           end
        else
           begin
           if Fch = '"' then
              begin
              Fch := nextChar;
              exit;
              end
           else
              begin
              FTokenRecord.FTokenString := FTokenRecord.FTokenString + Fch;
              Fch := nextChar;
              end
           end;
        end;
   raise EScannerError.Create ('string without terminating quotation mark');
end;


// Get special tokens
procedure TScanner.getSpecial;
begin
  case Fch of
     '+'  : FTokenRecord.Ftoken := tPlus;
     '^'  : FTokenRecord.Ftoken := tPower;
     '('  : FTokenRecord.Ftoken := tLeftParenthesis;
     ')'  : FTokenRecord.Ftoken := tRightParenthesis;
     '['  : FTokenRecord.Ftoken := tLeftBracket;
     ']'  : FTokenRecord.Ftoken := tRightBracket;
     '{'  : FTokenRecord.Ftoken := tLeftCurleyBracket;
     '}'  : FTokenRecord.Ftoken := tRightCurleyBracket;
     '!'  : begin
            if Char (FStreamReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenRecord.Ftoken := tNotEqual;
               end
            else
              raise EScannerError.Create ('unexpecting ''='' character after explanation point: ' + Fch);
            end;
     '>'  : begin
            if  Char (FStreamReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenRecord.Ftoken := tMoreThanOrEqual;
               end
            else
               FTokenRecord.Ftoken := tMoreThan;
            end;

     '<'  : begin
            if Char (FStreamReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenRecord.Ftoken := tLessThanOrEqual;
               end
            else
               FTokenRecord.Ftoken := tLessThan;
            end;

       '='  : begin
            if Char (FStreamReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenRecord.Ftoken := tEquivalence;
               end
            else
               FTokenRecord.Ftoken := tEquals;
            end;
     ';'  : FTokenRecord.Ftoken := tSemicolon;
     ':'  : FTokenRecord.Ftoken := tColon;
     ','  : FTokenRecord.Ftoken := tComma;
     '''' : FTokenRecord.Ftoken := tApostrophy;
     '-'  : FTokenRecord.Ftoken := tMinus;
     '/'  : FTokenRecord.Ftoken := tDivide;
     '*'  : FTokenRecord.Ftoken := tMult;
  else
     raise EScannerError.Create ('unrecongnised character in source coude: ' + Fch);
  end;
  Fch := nextChar;
end;


// Main pubic method that will be used by a parser
procedure TScanner.nextToken;
begin
  skipBlanksAndComments;

  // Record the position of the token then is coming up
  FTokenRecord.lineNumber := FLineNumber;
  FTokenRecord.columnNumber := FColumnNumber;

  case Fch of
     'a'..'z','A'..'Z','_' : getWord;

     '0'..'9', '.': getNumber;

     '"':   getString;

     EOF_CHAR :
          begin
          FTokenRecord.Ftoken := tEndofStream;
          if InMultiLineComment then
             raise EScannerError.Create ('detected unterminated comment, expecting "*/"');
          exit;
          end;

     else
          getSpecial;
  end;
end;


// --------------------------------------------------------------------

// Some debugging routines
function TScanner.TokenToString (tokenCode : TTokenCode) : string;
begin
  case tokenCode of
        tIdentifier   : result := 'identifier <' + FTokenRecord.FTokenString + '>';
        tInteger      : result := 'integer <' + inttostr (FTokenRecord.FTokenInteger) + '>';
        tFloat        : result := 'float <' + floattostr (FTokenRecord.FTokenFloat) + '>';
        tString       : result := 'string "' + FTokenRecord.FTokenString + '"';
        tMinus        : result := 'special: ''-''';
        tPlus         : result := 'special: ''+''';
        tMult         : result := 'special: ''*''';
        tDivide       : result := 'special: ''/''';
        tPower        : result := 'special: ''^''';
  tRightParenthesis   : result := 'special: '')''';
  tLeftParenthesis    : result := 'special: ''(''';
     tRightBracket    : result := 'special: '']''';
     tLeftBracket     : result := 'special: ''[''';
  tLeftCurleyBracket  : result := 'special: ''{''';
  tRightCurleyBracket : result :=  'special: ''}''';
        tEquals       : result := 'special: ''=''';
        tEquivalence  : result := 'special: ''==''';
        tMoreThan     : result := 'special: ''>''';
        tLessThan     : result := 'special: ''<''';
     tMoreThanOrEqual : result := 'special: ''>=''';
     tLessThanOrEqual : result := 'special: ''<=''';
        tApostrophy   : result := 'Apostrphy';
        tSemicolon    : result := 'special: '';''';
        tColon        : result := 'special: '':''';
        tComma        : result := 'special: '',''';
        tDollar       : result := 'special: ''$''';
             tEnd     : result := 'key word: <end>';
             tIf      : result := 'key word: <if>';
             tThen    : result := 'key word: <then> ';
             tFor     : Result := 'Key word: <for>';
             tTo      : result := 'key word: <to>';
            tWhile    : result := 'key word: <while>';
             tDo      : result := 'key word: <do>';
             tElse    : result := 'key word: <else>';
            tRepeat   : result := 'key word: <repeat>';
            tUntil    : result := 'key word: <until>';
        tEndofStream  : result := 'End of Stream';
  else
       result := 'unrecognised token in tokenToString: ' + inttostr (integer(tokenCode));
  end;
end;


// Returns a string representation of the most recently read Token
function TScanner.TokenToString : string;
begin
  Result := TokenToString (token);
end;


function TScanner.TokenLiteral : string;
begin
  case token of
       tIdentifier   : result := FTokenRecord.FTokenString;
       tInteger      : result := InttoStr (FTokenRecord.FTokenInteger);
       tFloat        : result := Format ('%g', [FTokenRecord.FTokenFloat]);
       tString       : result := FTokenRecord.FTokenString;
       tMinus        : result := '-';
       tPlus         : result := '+';
       tMult         : result := '*';
       tDivide       : result := '/';
       tPower        : result := '^';
 tRightParenthesis   : result := ')';
 tLeftParenthesis    : result := '(';
    tRightBracket    : result := ']';
     tLeftBracket    : result := '[';
 tLeftCurleyBracket  : result := '{';
 tRightCurleyBracket : result := '}';
       tEquals      : result := '=';
       tEquivalence : result := '==';
       tApostrophy : result := '''';
       tSemicolon  : result := ';';
       tColon      : result := ':';
       tComma      : result := ',';
       tDollar     : result := '$';
       tLessThan   : result := '<';
       tMoreThan   : result := '>';
            tEnd   : result := 'end';
            tIf    : result := 'if';
            tThen  : result := 'then';
            tDo    : result := 'do';
            tTo    : result := 'to';
            tOr    : result := 'or';
            tFor   : result := 'for';
            tAnd   : Result := 'and';
            tNot   : Result := 'not';
            tElse  : Result := 'else';
            tWhile : Result := 'while';
            tUntil : Result := 'until';
           tRepeat : Result := 'repeat';

   else
       result := 'unrecognised token in TokenLiteral';
  end;

end;


end.