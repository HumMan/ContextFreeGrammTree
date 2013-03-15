unit GetNameForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,

  RegExp;

type
  TGetNameForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;

    procedure FormShow(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    reg_expr:TNFA;
    err_msg:string;
  end;

var
  GetName: TGetNameForm;

implementation
{$R *.dfm}

procedure TGetNameForm.FormShow(Sender: TObject);
begin
  edit1.SetFocus;
end;

procedure TGetNameForm.Edit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if(key=13)then
  begin
    if(reg_expr.Match(edit1.Text))then ModalResult:=mrOk
    else MessageDlg(err_msg,mtError, [mbOK], 0)
  end;
end;

procedure TGetNameForm.Button1Click(Sender: TObject);
begin
  if(reg_expr.Match(edit1.Text))then ModalResult:=mrOk
    else MessageDlg(err_msg,mtError, [mbOK], 0);
end;

end.
