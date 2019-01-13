program FullSyntaxAnlaysisProject;

// Source code related to Chapter 9 for the book:
// Writing an Interpreter in Object Pascal: Part 1

// Syntax Parser for calculator project

// Developed under Delphi for Windows and Mac platforms.

// *** Ths source is distributed under Apache 2.0 ***

// Copyright (C) 2018 Herbert M Sauro

// Author Contact Information:
// email: hsauro@gmail.com

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows,
  ShellAPI,
  System.SysUtils,
  StrUtils,
  Math,
  IOUtils,
  uScanner in 'uScanner.pas',
  uSyntaxAnalysis in 'uSyntaxAnalysis.pas';

const
   RHODUS_VERSION = '1.0';

var sourceCode : string;
    sc : TScanner;
    sy : TSyntaxAnalysis;
    fileName : string;
    launchDir : string;


procedure displayWelcome;
begin
  writeln ('Welcome to Rhodus Recognizer Console, Version ', RHODUS_VERSION);
  writeln ('Data and Time: ', dateToStr (Date), ', ', timeToStr (Time));
  writeln ('Type quit to exit. Other commands: list, run, edit, dir');
end;


procedure displayPrompt;
begin
  write ('>> ');
end;

function getSampleScriptsDir : string;
begin
   result := TDirectory.GetParent(TDirectory.GetParent(getCurrentDir)) + '\SampleScripts';
end;


function runCommand (const src : string) : boolean;
var fileName, sdir : string;
begin
   sdir := getSampleScriptsDir + '\';
   result := False;
   if leftStr (src, 4) = 'list' then
      begin
      fileName := trim (rightStr (src, length (src) - 4));
      if TFile.Exists (sdir + fileName) then
         writeln (TFile.ReadAllText(sdir + fileName))
      else
         writeln ('No such file');
      result := True;
      end;
   if leftStr (src, 4) = 'edit' then
      begin
      fileName := trim (rightStr (src, length (src) - 4));
      ShellExecute(0, nil, PChar('notepad.exe'),
         PChar(sdir + '\' + fileName), nil, SW_SHOWNORMAL);
      result := True;
      end;
   if src = 'dir' then
      begin
      for fileName in TDirectory.GetFiles(sdir, '*.rh') do
          writeln (extractFileName (sdir + fileName));
      result := True;
    end;
end;


procedure runCode (const src : string);
begin
   sc.scanString(src);
   try
      sc.nextToken;
      sy.mainProgram;
      writeln ('Success');
   except
      on e:exception do
         writeln ('Error: ' + e.Message + ' at line number ' + inttostr (sc.tokenElement.lineNumber) + ' column: ' + inttostr (sc.tokenElement.columnNumber));
   end;
end;


begin
  launchDir := ExtractFileDir (ParamStr (0));
  sc := TScanner.Create;
  try
    sy := TSyntaxAnalysis.Create (sc);
    try
      displayWelcome;
      while True do
        begin
        try
          displayPrompt;
          readln (sourceCode);
          if sourceCode = 'quit' then
             break;
          if leftStr (sourceCode, 3) = 'run' then
             begin
             fileName := trim (rightStr (sourceCode, length (sourceCode) - 3));
             if TFile.Exists (getSampleScriptsDir + '\' + fileName) then
                begin
                runCode (TFile.ReadAllText(getSampleScriptsDir + '\' + fileName));
                continue;
                end
             else
                begin
                writeln ('File not found');
                continue;
                end;
             end
          else
             if runCommand (sourceCode) then
                continue;

          if sourceCode <> '' then
             runCode (sourceCode);
          except
            on e:exception do
               writeln (e.Message);
          end;
        end;
      writeln ('Press any key to exit');
      readln;
    finally
      sy.Free;
    end;
  finally
    sc.Free;
  end;
end.

