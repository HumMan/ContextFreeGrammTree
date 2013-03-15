object GetNameForm: TGetNameForm
  Left = 529
  Top = 318
  Width = 268
  Height = 111
  BorderStyle = bsSizeToolWin
  Caption = #1042#1074#1077#1076#1080#1090#1077' '#1080#1084#1103':'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 48
    Top = 48
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 144
    Top = 48
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 2
  end
  object Edit1: TEdit
    Left = 16
    Top = 16
    Width = 233
    Height = 21
    TabOrder = 0
    OnKeyDown = Edit1KeyDown
  end
end
