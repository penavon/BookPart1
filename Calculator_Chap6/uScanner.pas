unit uScanner;

// ------------------------------------------------------------------------
// TScanner - general purpose tokeniser
// Originally Written 11 Feb 1998 (HMS)
// This version heavily modified: 15 Nov, 2018
// ------------------------------------------------------------------------

// This particular verison is written for the calculator project in second half of Chapter 6

// Developed under Delphi for Windows and Mac platforms.
// Ths source is distributed under Apache 2.0

// Copyright (C) 1999-2018 Herbert M Sauro

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

   This version has special support for token look ahead:

   You can look ahead in the stream for the next token and put the token
   back into the stream using the token queue
}

interface

uses Windows, SysUtils, Classes, System.Character, Generics.Collections;

type
  { ********************* Lexical scanner types etc *********************** }
  EScannerError = class (Exception);

  TTokenCode = (tIdentifier,
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
                tUnaryMinus,
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
                tArrow,
                tAnd,
                tOr,
                tNot,
                tXor,
                tEnd,
                tEndofStream,

                tPrint,

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
                tFunction);

  TTokenSet = set of TTokenCode;

  TTokenElement = record
                    lineNumber, columnNumber : integer;
                    FToken        : TTokenCode;
                    FTokenString  : string;
                    FTokenFloat   : double;
                    FTokenInteger : Integer;
                  end;

  TScanner = class (TObject)
            private
               aQueue : TQueue<TTokenElement>;
               FromQueue : Boolean; // If false, scanner reads from stream else from token queue
               InMultiLineComment : Boolean;

               FTokenElement : TTokenElement;
               Fch : Char;  // The current character read from the stream

               FKeyWordList : TStringList;
               FLineNumber : integer;
               FColumnNumber : integer;
               yyReader : TStreamReader;

               procedure startScanner;
               procedure skipBlanksAndComments;
               procedure skipSingleLineComment;
               procedure skipMultiLIneComment;

               function  readRawChar : Char;
               function  getOS_IndependentChar : Char;
               function  nextChar : Char;

               function  isLetter (ch : Char) : boolean;
               function  isDigit (ch : Char) : boolean;
               procedure getWord;
               procedure getString;
               procedure getNumber;
               procedure getSpecial;
               procedure addKeyWords;
               function  isKeyWord (FTokenString : string; var Token : TTokenCode) : boolean;

               function getTokenCode : TTokenCode;
               function getTokenString : string;
               function getTokenInteger : integer;
               function getTokenDouble : double;
             public
               constructor create;
               destructor  destroy; override;

               procedure nextToken;
               procedure pushBackToken (token : TTokenElement);
               function  tokenToString : string; overload;
               function  tokenToString (tokenCode : TTokenCode) : string; overload;
               function  tokenLiteral : string;
               function  getScalar : double;

               procedure scanString (str : string);
               procedure scanFile (Filename : string);
               property  tokenElement : TTokenElement read FTokenElement;
               property  token : TTokenCode read getTokenCode;
               property  tokenString : string read getTokenString;
               property  tokenInteger : integer read getTokenInteger;
               property  tokenFloat : double read getTokenDouble;
            end;


implementation

Uses Math;

const
  MAX_DIGIT_COUNT  = 3; // Max # of digits in exponent of floating point number
  MAX_EXPONENT = 308;
  TAB = #09;      // TAB key
  LF = #10;       // Line feed character
  CR = #13;       // Carriage return character
  EOF_CHAR = Char ($FF);   // Defines end of string marker, used internally


constructor TScanner.Create;
begin
  inherited Create;
  addKeyWords;
  aQueue := TQueue<TTokenElement>.Create;  //  Use to push token back into the stream
  FromQueue := True; // Default to is get tokens from queue first then stream
end;


destructor TScanner.Destroy;
begin
  FKeyWordList.Free;
  freeAndNil(yyReader); // yyReader owns stream so stream will be freeed too.
  aQueue.Free;
  inherited Destroy;
end;


procedure TScanner.scanString (str : string);
begin
  freeAndNil(yyReader);
  // Use a reader because we'll have access to peek if we need it
  yyReader := TStreamReader.Create(TStringStream.Create (str, TEncoding.UTF8));
  yyReader.OwnStream;
  startScanner;
end;


procedure TScanner.scanFile (Filename : string);
begin
  freeAndNil (yyReader);
  yyReader := TStreamReader.Create(TBufferedFileStream.Create (filename, fmOpenRead), TEncoding.UTF8);
  yyReader.OwnStream;
  startScanner;
end;


procedure TScanner.startScanner;
begin
  FLineNumber := 1;
  FColumnNumber := 0;
  Fch := nextChar;
end;


function TScanner.getTokenCode : TTokenCode;
begin
  result := FTokenElement.FToken;
end;

function TScanner.getTokenString: string;
begin
  result := FTokenElement.FTokenString;
end;

function TScanner.getTokenInteger : integer;
begin
  result := FTokenElement.FTokenInteger;
end;

function TScanner.getTokenDouble: double;
begin
  result := FTokenElement.FTokenFloat;
end;


// Some predefined keywords
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
  FKeyWordList.AddObject ('print', TObject (tPrint));

  FKeyWordList.AddObject ('repeat', TObject (tRepeat));
  FKeyWordList.AddObject ('downto', TObject (tDownTo));

  FKeyWordList.AddObject ('function', TObject (tFunction));

  FKeyWordList.Sort;
end;


function TScanner.isKeyWord (FTokenString : string; var Token : TTokenCode) : boolean;
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
  if yyReader = nil then
     exit (char (EOF_CHAR));

  if yyReader.EndOfStream  then
     begin
     FreeAndNil (yyReader);
     result := char (EOF_CHAR);
     end
  else
     begin
     inc (FColumnNumber);
     result := Char (yyReader.Read);
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


procedure TScanner.skipSingleLineComment;
begin
  while (Fch <> LF) and (FCh <> EOF_CHAR) do
        Fch := getOS_IndependentChar;
  if FCh <> EOF_CHAR then
     Fch := nextChar;
end;


// Skip blanks, null characters and tabs
procedure TScanner.skipBlanksAndComments;
begin
  while Fch in [' ', TAB, '/']  do
        begin
        if (Fch in [' ', TAB])  then
           Fch := nextChar
        else
           begin
           // Check for start of comment
           if (char (yyReader.Peek) = '/') or (char (yyReader.Peek) = '*') then
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


// Scan in a number token, will distinguish between integer and float
// (including scientific notation) Valid numbers include:
// 23, 1.2, 0.3, .1234345, 1e3, 1e-6, 3.45667E-12
// Note: negative numbers not supported here, instead the '-' sign is read
// in as a separate token in its own right, therefore -1.2 yields two
// tokens when scanned, tMinus followed by tFloat. To obtain the negative number
// you would need to multiply TokenFloat by (-1). It was done this way so that
// unary minuses in things such as "-(1.2)" could be handled.
procedure TScanner.getNumber;
var singleDigit : integer; scale : double;
    evalue : integer;
    exponentSign : integer;
    cutOff : integer;
begin
  FTokenElement.FTokenInteger := 0; FTokenElement.FTokenFloat := 0.0;

  // Assume it's an integer
  FTokenElement.FToken := tINTEGER;
  // check for decimal point just in case user has typed something like .5
  if Fch <> '.' then
     repeat
       singleDigit := ord (Fch) - ord ('0');
       if FTokenElement.FTokenInteger <= (MaxInt - singleDigit) div 10 then
          begin
          FTokenElement.FTokenInteger := 10*FTokenElement.FTokenInteger + singleDigit;
          Fch := nextchar;
          end
       else
         raise EScannerError.Create ('integer overflow, constant value too large to read');
     until not isDigit (FCh);

  scale := 1;
  if Fch = '.' then
     begin
     // Then it's a float. Start collecting fractional part
     FTokenElement.FToken := tFLOAT; FTokenElement.FTokenFloat := FTokenElement.FTokenInteger;
     Fch := nextchar;

     while isDigit (FCh) do
        begin
        scale := scale * 0.1;
        singleDigit := ord (Fch) - ord ('0');
        FTokenElement.FTokenFloat := FTokenElement.FTokenFloat + (singleDigit * scale);
        Fch := nextchar;
        end;
     end;

   exponentSign := 1;
  // Next check for scientific notation
  if (Fch = 'e') or (Fch = 'E') then
     begin
     // Then it's a float. Start collecting exponent part
     if FTokenElement.FToken = tInteger then
        begin
        FTokenElement.FToken := tFLOAT;
        FTokenElement.FTokenFloat := FTokenElement.FTokenInteger;
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
        FTokenElement.FTokenFloat := FTokenElement.FTokenInteger * Math.IntPower (10, evalue)
     else
        FTokenElement.FTokenFloat := FTokenElement.FTokenFloat * Math.Power (10.0, evalue);
     end;
end;


function TScanner.getScalar : double;
begin
  result := 0.0;
  if (FTokenElement.FToken = tInteger) then
     result := FTokenElement.FTokenInteger;
  if (FTokenElement.FToken = tFloat) then
     result := FTokenElement.FTokenFloat;
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
  FTokenElement.FTokenString := '';

  while isLetter (Fch) or isDigit (Fch) do
        begin
        FTokenElement.FTokenString := FTokenElement.FTokenString + Fch;  // Inefficient but convenient
        Fch := nextchar;
        end;

  if IsKeyWord (FTokenElement.FTokenString, FTokenElement.FToken) then
     FTokenElement.FToken := FTokenElement.FToken
  else
     FTokenElement.FToken := tIdentifier;
end;



// Get a token of the form "abc"
procedure TScanner.getString;
begin
  FTokenElement.FTokenString := '';
  FTokenElement.FToken := tString;

  Fch := nextChar;
  while Fch <> EOF_CHAR do
        begin
        if Fch = '\' then
           begin
           Fch := nextChar;
           case Fch of
               '\' : FTokenElement.FTokenString := FTokenElement.FTokenString + '\';
               'n' : FTokenElement.FTokenString := FTokenElement.FTokenString + sLineBreak;
               'r' : FTokenElement.FTokenString := FTokenElement.FTokenString + CR;
               't' : FTokenElement.FTokenString := FTokenElement.FTokenString + TAB;
            else
               FTokenElement.FTokenString := FTokenElement.FTokenString + '\' + Fch;
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
              FTokenElement.FTokenString := FTokenElement.FTokenString + Fch;
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
     '+'  : FTokenElement.Ftoken := tPlus;
     '^'  : FTokenElement.Ftoken := tPower;
     '('  : FTokenElement.Ftoken := tLeftParenthesis;
     ')'  : FTokenElement.Ftoken := tRightParenthesis;
     '['  : FTokenElement.Ftoken := tLeftBracket;
     ']'  : FTokenElement.Ftoken := tRightBracket;
     '{'  : FTokenElement.Ftoken := tLeftCurleyBracket;
     '}'  : FTokenElement.Ftoken := tRightCurleyBracket;
     '!'  : begin
            if Char (yyReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenElement.Ftoken := tNotEqual;
               end
            else
              raise EScannerError.Create ('unexpecting ''='' character after explanation point: ' + Fch);
            end;
     '>'  : begin
            if  Char (yyReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenElement.Ftoken := tMoreThanOrEqual;
               end
            else
               FTokenElement.Ftoken := tMoreThan;
            end;

     '<'  : begin
            if Char (yyReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenElement.Ftoken := tLessThanOrEqual;
               end
            else
               FTokenElement.Ftoken := tLessThan;
            end;

       '='  : begin
            if Char (yyReader.Peek) = '=' then
               begin
               Fch := nextChar;
               FTokenElement.Ftoken := tEquivalence;
               end
            else
               FTokenElement.Ftoken := tEquals;
            end;
     ';'  : FTokenElement.Ftoken := tSemicolon;
     ':'  : FTokenElement.Ftoken := tColon;
     ','  : FTokenElement.Ftoken := tComma;
     '''' : FTokenElement.Ftoken := tApostrophy;
     '-'  : FTokenElement.Ftoken := tMinus;
     '/'  : FTokenElement.Ftoken := tDivide;
     '*'  : FTokenElement.Ftoken := tMult;
  else
     raise EScannerError.Create ('unrecongnised character in source coude: ' + Fch);
  end;
  Fch := nextChar;
end;


procedure TScanner.nextToken;
begin
  if aQueue.Count > 0 then
     FTokenElement := aQueue.Dequeue;

  skipBlanksAndComments;

  // Record the position of the token then is coming up
  FTokenElement.lineNumber := FLineNumber;
  FTokenElement.columnNumber := FColumnNumber;

  case Fch of
     'a'..'z','A'..'Z','_' : getWord;

     '0'..'9', '.': getNumber;

     '"':   getString;

     EOF_CHAR :
          begin
          FTokenElement.Ftoken := tEndofStream;
          if InMultiLineComment then
             raise EScannerError.Create ('detected unterminated comment, expecting "*/"');
          exit;
          end;

     else
          getSpecial;
  end;
end;



procedure TScanner.pushBackToken (token : TTokenElement);
begin
  aQueue.Enqueue(token);
end;



{ -------------------------------------------------------------------- }
{ Some debugging routines }

function TScanner.TokenToString (tokenCode : TTokenCode) : string;
begin
  case tokenCode of
        tIdentifier   : result := 'identifier <' + FTokenElement.FTokenString + '>';
        tInteger      : result := 'integer <' + inttostr (FTokenElement.FTokenInteger) + '>';
        tFloat        : result := 'float <' + floattostr (FTokenElement.FTokenFloat) + '>';
        tString       : result := 'string "' + FTokenElement.FTokenString + '"';
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
        tArrow        : result := 'special: ''->''';
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

        tEndofStream : result := 'End of Stream';
  else
       result := 'unrecognised token in tokenToString: ' + inttostr (integer(tokenCode));
  end;
end;


{ Returns a string representation of the most recently read Token }
function TScanner.TokenToString : string;
begin
  Result := TokenToString (token);
end;


function TScanner.TokenLiteral : string;
begin
  case token of
       tIdentifier   : result := FTokenElement.FTokenString;
       tInteger      : result := InttoStr (FTokenElement.FTokenInteger);
       tFloat        : result := Format ('%g', [FTokenElement.FTokenFloat]);
       tString       : result := FTokenElement.FTokenString;
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
       tArrow      : result := '->';
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