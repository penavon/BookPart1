unit uSymbolTable;

// A simple symbol table for Chapter 8 of the book:

// Writing an Interpreter for Object Pascal, Part 1

interface

Uses Generics.Collections;

type
  TSymbolTable =  TDictionary<string,double>;

  var symbolTable : TSymbolTable;

implementation


initialization
  symbolTable := TSymbolTable.Create;
finalization
  symbolTable.Free;
end.
