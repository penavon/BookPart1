object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Lex Tester'
  ClientHeight = 509
  ClientWidth = 823
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    823
    509)
  PixelsPerInch = 96
  TextHeight = 13
  object btnStart1: TButton
    Left = 32
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 0
    OnClick = btnStart1Click
  end
  object memoInput1: TMemo
    Left = 32
    Top = 63
    Width = 153
    Height = 338
    Anchors = [akLeft, akTop, akBottom]
    Lines.Strings = (
      '// A comment'
      'x = 3.1415'
      'y = 0.23456'
      'z = 3.12E6'
      'w = 56.45E-6'
      'x = 4 + 6'
      'y = x * 2'
      'print (x)'
      'println()'
      'print (y)'
      's = "Hello World"'
      'print (s)'
      'x = 3.1415'
      'y = x/y + 2.0^x;'
      'if x > 5 then'
      '   begin'
      '   x = x + 1'
      '   end;'
      'a = "abcdefg 1234'
      '  56678"'
      'b = "abcdefg 1234'
      'xyz"')
    TabOrder = 1
  end
  object memoInput2: TMemo
    Left = 200
    Top = 63
    Width = 153
    Height = 338
    Anchors = [akLeft, akTop, akBottom]
    Lines.Strings = (
      'x = 999'
      '// A'
      'y = 1234'
      '/* A com'
      'ment */ z= 567'
      'g = 67'
      '// Last comment')
    TabOrder = 2
  end
  object btnStart2: TButton
    Left = 200
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 3
    OnClick = btnStart2Click
  end
  object StringGrid: TStringGrid
    Left = 376
    Top = 63
    Width = 427
    Height = 338
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 3
    DefaultColWidth = 142
    DefaultRowHeight = 20
    FixedCols = 0
    RowCount = 20
    TabOrder = 4
  end
  object moResult: TMemo
    Left = 376
    Top = 407
    Width = 427
    Height = 89
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 5
  end
  object btnLoad: TButton
    Left = 728
    Top = 32
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Load File'
    TabOrder = 6
    OnClick = btnLoadClick
  end
  object OpenTextFileDialog: TOpenTextFileDialog
    Filter = 'Text files|*.txt|All Files|*.*'
    Left = 552
    Top = 16
  end
end
