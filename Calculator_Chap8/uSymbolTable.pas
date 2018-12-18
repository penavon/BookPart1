unit uSymbolTable;

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
