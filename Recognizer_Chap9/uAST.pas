unit uAST;

interface

Uses Classes, SysUtils, Generics.Collections, uScanner;

type
   TASTNode = class;

   TChildNodes = TList<TASTNode>;

   TASTNode = class (TObject)
      nodeType : integer;
      token  : TTokenCode;
      iValue : integer;
      dValue : double;
      sValue : string;
      FChildNodes : TChildNodes;
   public
      constructor create;
      destructor  destroy; override;

      constructor createLeaf (iValue : integer); overload;
      constructor createLeaf (dValue : double);  overload;
      constructor createLeaf (sValue : string); overload;
      class function  createNode (leftNode, rightNode : TASTNode; token : TTokenCode) : TASTNode;
      class function  toString (node : TASTNode) : string;
      class function  nodeToString (node : TASTNode) : string;
    end;

implementation

constructor TASTNode.create;
begin
  inherited Create;
  FChildNodes := TList<TASTNode>.Create;
end;


destructor TASTNode.destroy;
var i : integer;
begin
  for i  := 0 to FChildNodes.Count - 1 do
      FChildNodes[i].free;
  FChildNodes.free;
end;

constructor TASTNode.createLeaf (iValue : integer);
begin
  Create;
  token := tInteger;
  self.iValue  := iValue;
end;


constructor TASTNode.createLeaf (dValue : double);
begin
  Create;
  token := tFloat;
  self.dValue := dValue;
end;


constructor TASTNode.createLeaf (sValue : string);
begin
  Create;
  token := tString;
  self.dValue := dValue;
end;


class function TASTNode.createNode (leftNode, rightNode : TASTNode; token : TTokenCode) : TASTNode;
begin
  result := TASTNode.Create;
  result.token := token;
  result.FChildNodes.Add(leftNode);
  result.FChildNodes.Add(rightNode);
end;


class function TASTNode.nodeToString (node : TASTNOde) : string;
begin
  case node.token of
    tIdentifier: result := node.sValue;
    tFloat     : result := floattoStr (node.dValue);
    tInteger   : result := inttostr (node.iValue);
    tPlus      : result := '+';
    tMinus     : result := '-';
    tMult      : result := '*';
    tDivide    : result := '/';
    tPower     : result := '^';
  end;
end;


class function TASTNode.toString (node : TASTNode) : string;
var i : integer;
begin
  if node = nil then
     exit;

  result := TASTNode.nodeToString (node);
  for i  := 0 to node.FChildNodes.Count - 1 do
      begin
      result := result + TASTNode.toString (node.FChildNodes[i]);
      end;
end;

end.
