unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ContextFreeGrammTree, Menus, StdCtrls, HighlightMemo,
  ImgList, ToolWin, ExtCtrls;

type
  TForm1 = class(TForm)
    Splitter1: TSplitter;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    PopupMenu1: TPopupMenu;
    N6: TMenuItem;
    Del: TMenuItem;
    N8: TMenuItem;
    AddProd: TMenuItem;
    AddNeterm: TMenuItem;
    N11: TMenuItem;
    AddAND: TMenuItem;
    AddOR: TMenuItem;
    AddAnyTimes: TMenuItem;
    AddTerm: TMenuItem;
    ImageList1: TImageList;
    N7: TMenuItem;
    N9: TMenuItem;
    Panel1: TPanel;
    OpenDialog: TOpenDialog;
    N14: TMenuItem;
    N15: TMenuItem;
    N16: TMenuItem;
    SaveDialog: TSaveDialog;
    ZeroOrOneTimes: TMenuItem;
    OneOrMoreTimes: TMenuItem;
    N19: TMenuItem;
    N20: TMenuItem;
    N21: TMenuItem;
    N22: TMenuItem;
    ScriptOpenDialog: TOpenDialog;
    N3: TMenuItem;
    N4: TMenuItem;
    N10: TMenuItem;
    ToolBar1: TToolBar;
    N5: TMenuItem;
    ToolButton1: TToolButton;
    ImageList2: TImageList;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ScriptSaveDialog: TSaveDialog;
    N12: TMenuItem;
    ToolButton9: TToolButton;
    Panel2: TPanel;
    ListBox1: TListBox;
    Splitter2: TSplitter;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TreeView: TContextFreeGrammTree;
    TabSheet3: TTabSheet;
    HighlightMemo1: THighlightMemo;
    StatusBar1: TStatusBar;
    StatusBar2: TStatusBar;
    ScriptSource: THighlightMemo;
    TreeView1: TTreeView;
    PopupMenu2: TPopupMenu;
    N13: TMenuItem;
    N17: TMenuItem;
    procedure DelClick(Sender: TObject);
    procedure N14Click(Sender: TObject);
    procedure N15Click(Sender: TObject);
    procedure N21Click(Sender: TObject);
    procedure N22Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure OpenScript;
    procedure SaveScript;
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton4Click(Sender: TObject);
    procedure ToolButton8Click(Sender: TObject);
    procedure ToolButton7Click(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton9Click(Sender: TObject);
    procedure N12Click(Sender: TObject);

    procedure ListBox1DblClick(Sender: TObject);
    procedure TreeViewContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure AddProdClick(Sender: TObject);
    procedure AddNetermClick(Sender: TObject);
    procedure AddTermClick(Sender: TObject);
    procedure AddANDClick(Sender: TObject);
    procedure AddORClick(Sender: TObject);
    procedure AddAnyTimesClick(Sender: TObject);
    procedure ZeroOrOneTimesClick(Sender: TObject);
    procedure OneOrMoreTimesClick(Sender: TObject);
    procedure HighlightMemo1UpdateLineCol(Sender: TObject; Line,
      Col: Integer);
    procedure ScriptSourceUpdateLineCol(Sender: TObject; Line,
      Col: Integer);
    procedure FormCreate(Sender: TObject);
    procedure HighlightMemo1Change(Sender: TObject);
    procedure TreeViewEdited(Sender: TObject; Node: TTreeNode;
      var S: String);
    procedure N13Click(Sender: TObject);
    procedure N17Click(Sender: TObject);
      private
    { Private declarations }
    procedure SaveSyntaxToFile;
    procedure LoadSyntaxFromFile;
  public
    { Public declarations }
  end;



var
  Form1: TForm1;

implementation
uses
  CommCtrl,StrUtils;

{$R *.dfm}

procedure TForm1.SaveSyntaxToFile;
var fname:string;
begin
  if(savedialog.Execute)then
  begin
    if Pos('.txt',savedialog.FileName)=0 then
      fname:=savedialog.FileName+'.txt'
    else
      fname:=savedialog.FileName;
    treeView.SaveGrammToFile(fname);
  end;
end;

procedure TForm1.LoadSyntaxFromFile;
begin
  if(opendialog.Execute)then
    treeview.LoadGrammFromFile(opendialog.Files[0]);
end;

procedure TForm1.DelClick(Sender: TObject);
begin
  treeview.DeleteSelectedNode;
end;

procedure TForm1.N14Click(Sender: TObject);
begin
  SaveSyntaxToFile
end;

procedure TForm1.N15Click(Sender: TObject);
begin
  LoadSyntaxFromFile;
end;

procedure TForm1.N21Click(Sender: TObject);
begin
  treeview.BeginUpdateItems;
  treeview.FullExpand;
  treeview.EndUpdateItems;
end;

procedure TForm1.N22Click(Sender: TObject);
begin
  treeview.BeginUpdateItems;
  treeview.FullCollapse;
  treeview.EndUpdateItems;
end;

procedure TForm1.OpenScript;
var s:string;
    f:TfileStream;
begin
if(scriptopendialog.Execute)then
  begin
    scriptSource.Clear;
    f:=Tfilestream.Create(scriptopendialog.Files[0],fmOpenRead);
    SetLength(s,f.size);
    f.ReadBuffer(pointer(s)^,f.Size);
    f.Free;
    scriptSource.Text:=s;
  end
end;



procedure TForm1.SaveScript;
var f:Tfilestream;
begin
  if(scriptsavedialog.Execute)then
  begin
    if Pos('.txt',scriptsavedialog.FileName)=0 then
      f:=Tfilestream.Create(scriptsavedialog.FileName+'.txt',fmCreate)
    else
      f:=Tfilestream.Create(scriptsavedialog.FileName,fmCreate);
    f.WriteBuffer(pointer(scriptsource.Text)^,length(scriptsource.Text));
    f.Free;
  end;
end;


procedure TForm1.N2Click(Sender: TObject);
begin
  OpenScript
end;

procedure TForm1.N10Click(Sender: TObject);
begin
  treeView.Validate(true);
end;

procedure TForm1.N4Click(Sender: TObject);
begin
  treeview.SetFocus;
  treeView.Validate(false);
end;

procedure TForm1.ToolButton5Click(Sender: TObject);
begin
  SaveSyntaxToFile
end;

procedure TForm1.ToolButton4Click(Sender: TObject);
begin
  LoadSyntaxFromFile
end;

procedure TForm1.ToolButton8Click(Sender: TObject);
begin
  treeview.SetFocus;
  treeView.Validate(false);
end;

procedure TForm1.ToolButton7Click(Sender: TObject);
begin
  treeView.Validate(true);
end;

procedure TForm1.ToolButton1Click(Sender: TObject);
begin
  OpenScript
end;

procedure TForm1.ToolButton9Click(Sender: TObject);
begin
  SaveScript
end;

procedure TForm1.N12Click(Sender: TObject);
begin
  SaveScript
end;

procedure TForm1.ListBox1DblClick(Sender: TObject);
var s,r:string;
    i1,i2:integer;
begin
  if listbox1.Items.Count>0 then
    if pos('[ Warning ]',listbox1.Items.strings[listbox1.ItemIndex])<>0 then
    begin
      s:=listbox1.Items.strings[listbox1.ItemIndex];
      i1:=pos('"',s);
      i2:=posEx('"',s,i1+1);
      r:=Copy(s,i1+1,i2-i1-1);
      treeview.SetFocus;
      treeview.FindProd(r).Selected:=true;
    end;
end;


procedure TForm1.TreeViewContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
   tmpNode: TTreeNode;
   t:TContextFreeGrammTree;
begin
  t:=(Sender as TContextFreeGrammTree);
  tmpNode := t.GetNodeAt(MousePos.X, MousePos.Y);
  if tmpNode <> nil then
    t.Selected := tmpNode;
  del.enabled:=t.Selected<>nil;
  AddTerm.Enabled:=t.CanAddNotProd;
  AddNeterm.enabled:=t.CanAddNotProd;
  AddOR.enabled:=t.CanAddNotProd;
  AddAND.enabled:=t.CanAddNotProd;
  AddAnyTimes.enabled:=t.CanAddNotProd;
  ZeroOrOneTimes.enabled:=t.CanAddNotProd;
  OneOrMoreTimes.enabled:=t.CanAddNotProd;
end;

procedure TForm1.AddProdClick(Sender: TObject);
begin
  TreeView.AddProd;
end;

procedure TForm1.AddNetermClick(Sender: TObject);
begin
  TreeView.AddNotTerm;
end;

procedure TForm1.AddTermClick(Sender: TObject);
begin
  TreeView.AddTerm;
end;

procedure TForm1.AddANDClick(Sender: TObject);
begin
  TreeView.AddAnd;
end;

procedure TForm1.AddORClick(Sender: TObject);
begin
  TreeView.AddOr;
end;

procedure TForm1.AddAnyTimesClick(Sender: TObject);
begin
  TreeView.AddAnyTimes;
end;

procedure TForm1.ZeroOrOneTimesClick(Sender: TObject);
begin
  TreeView.AddZeroOrOneTImes;
end;

procedure TForm1.OneOrMoreTimesClick(Sender: TObject);
begin
  TreeView.AddOneOrMoreTimes;
end;

procedure TForm1.HighlightMemo1UpdateLineCol(Sender: TObject; Line,
  Col: Integer);
begin
  statusbar1.Panels.Items[0].Text:='('+inttostr(line)+':'+inttostr(col)+')';
  statusbar1.Panels.Items[1].Text:=inttostr(HighlightMemo1.SelStart);
  statusbar1.Panels.Items[2].Text:=inttostr(HighlightMemo1.SelLength);
end;

procedure TForm1.ScriptSourceUpdateLineCol(Sender: TObject; Line,
  Col: Integer);
begin
  statusbar2.Panels.Items[0].Text:='('+inttostr(line)+':'+inttostr(col)+')';
  statusbar2.Panels.Items[1].Text:=inttostr(ScriptSource.SelStart);
  statusbar2.Panels.Items[2].Text:=inttostr(ScriptSource.SelLength);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  HighlightMemo1.AddExpr('lxm([a-z_0-9]{r})*',clRed);
  HighlightMemo1.AddExpr('lxm([a-z_0-9]{r})*\s*:',clRed);
  HighlightMemo1.AddExpr('([a-z_0-9]{r})*\s*:',clGreen);
  HighlightMemo1.AddExpr('([a-z_0-9]{r})*',clBlue);
  HighlightMemo1.AddExpr('[\(\):\+\*\?]',clBlack);
  HighlightMemo1.AddExpr('''([^'']|\\'')*''?',clMaroon);
  treeview.UpdateFromGrammSource;
  treeview.UpdateGrammSource;
end;

procedure TForm1.HighlightMemo1Change(Sender: TObject);
begin
  treeview.UpdateFromGrammSource;
end;

procedure TForm1.TreeViewEdited(Sender: TObject; Node: TTreeNode;
  var S: String);
begin
  node.Text:=s;
  treeview.UpdateGrammSource;
end;

procedure TForm1.N13Click(Sender: TObject);
begin
  treeview1.Items.BeginUpdate;
  treeview1.FullCollapse;
  treeview1.Items.EndUpdate;
end;

procedure TForm1.N17Click(Sender: TObject);
begin
  treeview1.Items.BeginUpdate;
  treeview1.FullExpand;
  treeview1.Items.EndUpdate;
end;

end.
