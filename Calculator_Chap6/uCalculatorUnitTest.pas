unit uCalculatorUnitTest;

interface
uses
  SysUtils, DUnitX.TestFramework, uScanner, uSyntaxAnalysis;

type

  [TestFixture]
  TCalculatorTest = class(TObject)
  private
     sc : TScanner;
     sy : TSyntaxAnalysis;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('Test1','1,1')]
    [TestCase('Test2','+1,1')]
    [TestCase('Test3','-1,-1')]
    [TestCase('Test4','-2,-2')]
    [TestCase('Test5','+123,123')]
    [TestCase('Test6','2+3,5')]
    [TestCase('Test7','2-3,-1')]
    [TestCase('Test8','2*3,6')]
    [TestCase('Test9','6/2,3')]
    [TestCase('Test10','2.4+2.1,4.5')]
    [TestCase('Test11','2.4-2.2,0.2')]
    [TestCase('Test12','2.4*2.2,5.28')]
    [TestCase('Test13','6.5/2.4,2.708333333')]
    [TestCase('Test14','2*3+4,10')]
    [TestCase('Test15','2+3*4,14')]
    [TestCase('Test16','1 + 2 - 3 - 5 - 1 + 0 - 4 + 2,-8')]
    [TestCase('Test17','2*1*3*5*3*2,180')]
    [TestCase('Test18','(2),2')]
    [TestCase('Test19','(2+4),6')]
    [TestCase('Test20','(2+3)*4,20')]
    [TestCase('Test21','(((2))),2')]
    [TestCase('Test22','((2)+4)*((5)),30')]
    [TestCase('Test23','-2+24,22')]
    [TestCase('Test24','3-(-5),8')]
    [TestCase('Test25','+5-(+7),-2')]
    [TestCase('Test26','-5+(-7),-12')]
    [TestCase('Test27','-2*(3-5)+7,11')]
    [TestCase('Test28','5.5*(2-3 + (5.3-7.89)/2)/2,-6.31125')]
    [TestCase('Test29','2-(32-4)/(23+(4)/(5))-(2-4)*(4+6-98.2)+4,-171.5764705882352')]
    [TestCase('Test31','2^3,8')]
    [TestCase('Test31','8^(-1^(-8^7)),0.125')]
    [TestCase('Test32','2^(-3),0.125')]
    [TestCase('Test33','2^0.7,1.624505')]
    [TestCase('Test34','4^3^2,262144')]
    [TestCase('Test35','(4^3)^2,4096')]
    [TestCase('Test36','0.9^0.8^0.7^0.6^0.5,0.9148883')]
    [TestCase('Test37','-2^3,-8')]
    [TestCase('Test38','2/3/4,0.166666666')]
    [TestCase('Test39','2--3,5')]
    [TestCase('Test40','2---3,-1')]
    [TestCase('Test41','2---3^4,-79')]
    [TestCase('Test42','2*-(1+2)^-(2+5*-(2+4)),-4.5753584909922e+13')]
    [TestCase('Test43','2//,2')]
    procedure TestCalculator( const sourceCode : string; const expectedResult : double);
    [Test]
    procedure TestDivideByZero;
    [Test]
    procedure TestUnbalancedParentheses;

  end;

implementation

procedure TCalculatorTest.Setup;
begin
  sc := TScanner.Create;
  sy := TSyntaxAnalysis.Create (sc);
end;

procedure TCalculatorTest.TearDown;
begin
  sc.Free;
  sy.Free;
end;


procedure TCalculatorTest.TestCalculator( const sourceCode : string; const expectedResult : double);
var value : double;
begin
  sc.scanString(sourceCode);
  sc.nextToken;
  value := sy.expression;
  assert.AreEqual(expectedResult, value, 1E-6, 'Floating point equality failure');
end;


procedure TCalculatorTest.TestDivideByZero ;
var value : double;
begin
  sc.scanString('1/0');
  Assert.WillRaise(procedure begin sc.nextToken; sy.expression; end, EZeroDivide, 'Divide by zero');
end;


procedure TCalculatorTest.TestUnbalancedParentheses;
var value : double;
begin
  sc.scanString('(0');
  Assert.WillRaise(procedure begin sc.nextToken; sy.expression; end, ESyntaxException, 'Unbalanced parenthesis');
end;


initialization
  TDUnitX.RegisterTestFixture(TCalculatorTest);
end.
