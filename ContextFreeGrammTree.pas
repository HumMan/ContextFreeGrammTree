unit ContextFreeGrammTree;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, Menus,

  GetNameForm,RegExp,GrammTree,GrammSourceParser,HighlightMemo;

type

    TContextFreeGrammTree = class(TCustomTreeView)
    private
      getname_form:TGetNameForm;
      gramm_tree:TGrammNode;
      script_source:TMemo;
      gramm_source:THighlightMemo;
      gramm_parse_result:TTreeView;
      log:TListBox;
      nterm_reg_exp,
      term_reg_exp:TNFA;
      is_updating_gramm_source,
      is_updating_tree:boolean;
      procedure TreeViewDragDrop(Sender, Source: TObject; X, Y: Integer);
      procedure TreeViewDragOver(Sender, Source: TObject; X, Y: Integer;
                  State: TDragState; var Accept: Boolean);
      procedure TreeViewCustomDrawItem(Sender: TCustomTreeView;
                  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
      //
      function GetName(use_reg_exp:TNFA;use_error_msg:string;var res_name:string):boolean;
      function IsContainNode(parent_node,node:TtreeNode):boolean;
      procedure CopyTo(source_node,target_node:TtreeNode);
      procedure AddOp(t:TGrammNodeType);
      procedure AddTermNotTerm(t:TGrammNodeType;name:string);
      procedure AddProd(t: TGrammNodeType;name: string);overload;
      procedure BuildFromGrammTree(view_node:TTreeNode;gramm_node:TGrammNode);
      procedure ChangeFromGrammTree(view_node:TTreeNode;gramm_node,previous_gramm_node:TGrammNode);
      function NeedChanging(gramm_node,previous_gramm_node:TGrammNode):boolean;
    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure SaveGrammToFile(file_name:string);
      procedure LoadGrammFromFile(file_name:string);
      function Validate(validate_script:boolean):boolean;
      function FindProd(s:string):TtreeNode;
      procedure DeleteSelectedNode;
      procedure BeginUpdateItems;
      procedure EndUpdateItems;
      procedure UpdateFromGrammSource;
      procedure UpdateGrammSource;
      function CanAddNotProd:boolean;
      procedure AddTerm;
      procedure AddNotTerm;
      procedure AddProd;overload;
      procedure AddOr;
      procedure AddAnd;
      procedure AddAnyTimes;
      procedure AddZeroOrOneTImes;
      procedure AddOneOrMoreTimes;
    published
      property GrammParseResult:TTreeView read gramm_parse_result write gramm_parse_result;
      property ScriptSource:TMemo read script_source write script_source;
      property GrammSource:THighlightMemo read gramm_source write gramm_source;
      property LogOut:TListBox read log write log;
      property Align;
      //
      property Anchors;
      property AutoExpand;
      property BevelEdges;
      property BevelInner;
      property BevelOuter;
      property BevelKind default bkNone;
      property BevelWidth;
      property BiDiMode;
      property BorderStyle;
      property BorderWidth;
      property ChangeDelay;
      property Color;
      property Ctl3D;
      property Constraints;
      property DragCursor;
      property Enabled;
      property Font;
      property HotTrack;
      property Images;
      property Indent;
      property ParentBiDiMode;
      property ParentColor default False;
      property ParentCtl3D;
      property ParentFont;
      property ParentShowHint;
      property PopupMenu;
      property RowSelect;
      property ShowButtons;
      property ShowHint;
      property ShowLines;
      property ShowRoot;
      property StateImages;
      property TabOrder;
      property TabStop default True;
      property ToolTips;
      property Visible;
      property OnAddition;
      property OnAdvancedCustomDraw;
      property OnAdvancedCustomDrawItem;
      property OnChange;
      property OnChanging;
      property OnClick;
      property OnCollapsed;
      property OnCollapsing;
      property OnCompare;
      property OnContextPopup;
      property OnCreateNodeClass;
      property OnDblClick;
      property OnDeletion;
      property OnEdited;
      property OnEditing;
      property OnEndDock;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnExpanding;
      property OnExpanded;
      property OnGetImageIndex;
      property OnGetSelectedIndex;
      property OnKeyDown;
      property OnKeyPress;
      property OnKeyUp;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
    end;

procedure Register;

implementation

constructor TContextFreeGrammTree.Create(AOwner: TComponent);
begin
  inherited;
  getname_form:=TGetNameForm.Create(self);
  OnDragDrop:=TreeViewDragDrop;
  OnDragOver:=TreeViewDragOver;
  OnCustomDrawItem:=TreeViewCustomDrawItem;
  DragMode:=dmAutomatic;
  rightClickSelect:=true;
  //
  nterm_reg_exp:=TNFA.Create;
  nterm_reg_exp.SetExpression('([a-z_0-9]{r})*');
  term_reg_exp:=TNFA.Create;
  term_reg_exp.SetExpression('.*');
  is_updating_gramm_source:=false;
  is_updating_tree:=false;
  SortType:=stNone;
end;

destructor TContextFreeGrammTree.Destroy;
begin
  getname_form.Free;
  nterm_reg_exp.Free;
  term_reg_exp.Free;
  gramm_tree.Free;
  inherited;
end;

function TContextFreeGrammTree.FindProd(s:string):TtreeNode;
var t:TtreeNode;
begin
  t:=Items.GetFirstNode;
  while t<>nil do
  begin
    if (t.Text=s)then
    begin
      result:=t;
      exit;
    end;
    t:=t.getNextSibling;
  end;
  result:=nil;
end;

function TContextFreeGrammTree.GetName(use_reg_exp:TNFA;use_error_msg:string;var res_name:string):boolean;
begin
  getname_form.err_msg:=use_error_msg;
  getname_form.reg_expr:=use_reg_exp;
  if(getname_form.ShowModal=mrOk)then
  begin
    res_name:=getname_form.Edit1.Text;
    result:=true;
  end
  else result:=false;
end;

procedure TContextFreeGrammTree.CopyTo(source_node,target_node:TtreeNode);
  var child,t:TtreeNode;
begin
  child:=source_node.getFirstChild;
  while (child<>nil) do
  begin
    t:=Items.AddChild(target_node,child.Text);
    t.ImageIndex:=child.ImageIndex;
    t.SelectedIndex:=t.ImageIndex;
    CopyTo(child,t);
    child:=child.getNextSibling;
  end;
end;


procedure TContextFreeGrammTree.SaveGrammToFile(file_name:string);
var f:Tfilestream;
    s:string;
begin
  try
    f:=Tfilestream.Create(file_name,fmCreate);
    s:=gramm_source.Text;
    f.WriteBuffer(pointer(s)^,length(s));
  finally
    f.Free;
  end;
end;

procedure TContextFreeGrammTree.LoadGrammFromFile(file_name:string);
var f:Tfilestream;
    s:string;
    gramm_source_parser:TGrammSourceParser;
begin
  Items.BeginUpdate;
  Items.Clear;
  gramm_source_parser:=TGrammSourceParser.Create;
  try
    f:=Tfilestream.Create(file_name,fmOpenRead);
    SetLength(s,f.size);
    f.ReadBuffer(pointer(s)^,f.Size);
    gramm_source_parser.StartParsing(s);
    gramm_tree.Free;
    gramm_tree:=TgrammNode.Create(G_ROOT,'main node');
    try
      gramm_tree.LoadGramm(gramm_source_parser,log);
    except
      on E:Exception do MessageDlg(E.Message,mtError, [mbOK], 0);
    end;
    BuildFromGrammTree(nil,gramm_tree);
  finally
    //gramm_tree.Free;
    f.Free;
  end;
  gramm_source_parser.Free;
  Items.EndUpdate;
  UpdateGrammSource;
end;

function TContextFreeGrammTree.Validate(validate_script:boolean):boolean;
var
  node:TgrammNode;
  prod:TtreeNode;
  i,curr_char:integer;
begin
  result:=true;
  try
    prod:=Items.GetFirstNode;
    if prod=nil then raise Exception.Create('Отсутствует грамматика!');
    gramm_tree.Free;
    gramm_tree:=TgrammNode.Create(prod,nil,G_ROOT,'main node');
    gramm_tree.ValidateProdsNames;
    gramm_tree.InitRefs(gramm_tree);
    node:=gramm_tree.FindProd('Script');
    if(node=nil)then
      raise Exception.Create('Не найдена начальная продукция!');
    //
    for i:=0 to gramm_tree.GetChildsHigh do with gramm_tree.GetChild(i)do
      checked:=false;
    log.Clear;
    //
    if(not gramm_tree.ValidateSyntax(gramm_tree))then
      raise Exception.Create('Синтаксическая ошибка!');
    //
    for i:=0 to gramm_tree.GetChildsHigh do
      if (not gramm_tree.GetChild(i).checked)and(gramm_tree.GetChild(i).GetName<>'Script') then
        log.Items.Add('[ Warning ]: Продукция "'+gramm_tree.GetChild(i).GetName+'" нигде не используется!');
    //
    if(validate_script)then
    begin

      if(length(script_source.Text)=0)then
        raise Exception.Create('Отсутствует скрипт!');
      curr_char:=1;
      gramm_parse_result.Items.Clear;
      gramm_parse_result.Items.BeginUpdate;
      if(not node.ValidateScript(script_source.Text,curr_char,gramm_parse_result,true))then
        raise Exception.Create('Скрипт не соответствует грамматике!');
      if curr_char<=Length(scriptSource.Text) then
        raise Exception.Create('Скрипт обработан не до конца(последний символ '+inttostr(curr_char)+')!');
    end;
  except
    on E:Exception do
    begin
      MessageDlg(E.Message,mtError, [mbOK], 0);
      result:=false;
    end;
  end;
  gramm_parse_result.Items.EndUpdate;
  //gramm_tree.Free;
end;

function TContextFreeGrammTree.IsContainNode(parent_node,node:TtreeNode):boolean;
var child:TtreeNode;
begin
  if node=parent_node then
  begin
    result:=true;
    exit;
  end;
  result:=false;
  child:=parent_node.getFirstChild;
  while (child<>nil) do
  begin
    result:=IsContainNode(child,node);
    if(result)then Exit;
    child:=child.getNextSibling;
  end;
end;

function IsOperator(i:integer):boolean;
begin
  result:=i in[ord(G_OR),ord(G_AND),ord(G_ANY_TIMES),
         ord(G_ZERO_OR_ONE_TIMES),ord(G_ONE_OR_MORE_TIMES)];
end;

procedure TContextFreeGrammTree.TreeViewDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  TargetNode, SourceNode,t: TTreeNode;
  tar,sor:TGrammNodeType;
begin
    TargetNode := GetNodeAt(X, Y);
    SourceNode := Selected;
    if(IsContainNode(sourcenode,TargetNode))then exit;
    if (TargetNode = nil) then
    begin
      EndDrag(False);
      Exit;
    end;
    tar:=TGrammNodeType(TargetNode.ImageIndex);
    sor:=TGrammNodeType(SourceNode.ImageIndex);
    if ((tar in [G_TERM,G_NTERM])and(sor in [G_TERM,G_NTERM]))or
       ((tar in [G_TERM,G_NTERM])and IsOperator(ord(sor)))or
       ((tar=G_PROD)and(sor=G_PROD))then
    begin
    if(getkeyState(VK_LCONTROL)in[0,1])then
        SourceNode.MoveTo(TargetNode,naInsert)
      else
      begin
        t:=Items.Insert(targetNode,SourceNode.Text);
        t.ImageIndex:=SourceNode.ImageIndex;
        t.SelectedIndex:=t.ImageIndex;
        CopyTo(SourceNode,t);
      end;
    end
    else
    if ((tar=G_PROD)          and(sor in [G_TERM,G_NTERM]))or
       (IsOperator(ord(tar))  and IsOperator(ord(sor)))or
       (IsOperator(ord(tar))  and(sor in [G_TERM,G_NTERM]))or
       ((tar=G_PROD)          and IsOperator(ord(sor)))then
    begin
    if(getkeyState(VK_LCONTROL)in[0,1])then
        SourceNode.MoveTo(TargetNode,naAddChildFirst)
      else
      begin
        t:=Items.AddChild(targetNode,SourceNode.Text);
        t.ImageIndex:=SourceNode.ImageIndex;
        t.SelectedIndex:=t.ImageIndex;
        CopyTo(SourceNode,t);
      end;
    end;
    UpdateGrammSource
end;

procedure TContextFreeGrammTree.TreeViewDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  if (Sender = self) then
  begin
    Accept := True;
  end;
end;

procedure TContextFreeGrammTree.TreeViewCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if Pos('lxm',Node.Text)=1 then
  begin
  Sender.Canvas.Font.Color:=clMaroon;
  Sender.Canvas.Font.Style := Sender.Canvas.Font.Style + [fsBold];
  end;
end;

procedure Register;
begin
  RegisterComponents('Standard', [TContextFreeGrammTree]);
end;

procedure TContextFreeGrammTree.DeleteSelectedNode;
begin
  if selected<>nil then Items.Delete(Selected);
  UpdateGrammSource
end;

procedure TContextFreeGrammTree.BeginUpdateItems;
begin
  items.BeginUpdate;
end;

procedure TContextFreeGrammTree.EndUpdateItems;
begin
  items.EndUpdate;
end;

procedure TContextFreeGrammTree.AddAnd;
begin
  AddOp(G_AND);
end;

procedure TContextFreeGrammTree.AddAnyTimes;
begin
  AddOp(G_ANY_TIMES);
end;

procedure TContextFreeGrammTree.AddNotTerm;
var s:string;
begin
  if GetName(nterm_reg_exp,'Имена могут состоять из латинских букв, цифр и символа подчеркивания!',s)then
    AddTermNotTerm(G_NTERM,s);
end;

procedure TContextFreeGrammTree.AddOneOrMoreTimes;
begin
  AddOp(G_ONE_OR_MORE_TIMES);
end;

procedure TContextFreeGrammTree.AddOr;
begin
  AddOp(G_OR);
end;

procedure TContextFreeGrammTree.AddProd;
var s:string;
begin
  if GetName(nterm_reg_exp,'Имена могут состоять из латинских букв, цифр и символа подчеркивания!',s)then
    AddProd(G_PROD,s);
end;

procedure TContextFreeGrammTree.AddTerm;
var s:string;
begin
  if GetName(term_reg_exp,'Терминалы могут состоять из любых символов, кроме последовательности одинарной кавычки и пробела!',s)then
    AddTermNotTerm(G_TERM,s);
end;

procedure TContextFreeGrammTree.AddZeroOrOneTImes;
begin
  AddOp(G_ZERO_OR_ONE_TIMES);
end;

function TContextFreeGrammTree.CanAddNotProd: boolean;
begin
  result:=(Selected<>nil) and not (Selected.ImageIndex in[ord(G_NTERM),ord(G_TERM)]);
end;

procedure TContextFreeGrammTree.AddOp(t:TGrammNodeType);
var
  node: ttreeNode;
begin
  assert(IsOperator(ord(t)));
  node:=Items.AddChild(Selected,nodes_names[ord(t)]);
  node.ImageIndex:=ord(t);
  node.SelectedIndex:=node.ImageIndex;
  UpdateGrammSource
end;

procedure TContextFreeGrammTree.AddTermNotTerm(t: TGrammNodeType;
  name: string);
var
  node: ttreeNode;
begin
  assert(t in[G_TERM,G_NTERM]);
  node:=Items.AddChild(Selected,name);
  node.ImageIndex:=ord(t);
  node.SelectedIndex:=node.ImageIndex;
  UpdateGrammSource
end;

procedure TContextFreeGrammTree.AddProd(t: TGrammNodeType; name: string);
var
  node: ttreeNode;
begin
  node:=Items.AddChild(nil,name);
  node.ImageIndex:=ord(G_PROD);
  node.SelectedIndex:=node.ImageIndex;
  UpdateGrammSource
end;

procedure TContextFreeGrammTree.UpdateFromGrammSource;
var gramm_source_parser:TGrammSourceParser;
    new_gramm_tree:TGrammNode;
begin
  if is_updating_gramm_source then exit;
  is_updating_tree:=true;
  items.BeginUpdate;
  //Items.Clear;
  log.Clear;
  gramm_source_parser:=TGrammSourceParser.Create;
  gramm_source_parser.StartParsing(gramm_source.Text);
  //gramm_tree.Free;
  new_gramm_tree:=TgrammNode.Create(G_ROOT,'main node');
  try
    new_gramm_tree.LoadGramm(gramm_source_parser,log);
  except
    on E:Exception do log.Items.Add('[ Error ]: '+E.Message);
  end ;
  ChangeFromGrammTree(nil,new_gramm_tree,gramm_tree);
  //BuildFromGrammTree(nil,gramm_tree);
  gramm_tree.Free;
  gramm_tree:=new_gramm_tree;
  gramm_source_parser.Free;
  Items.EndUpdate;
  is_updating_tree:=false;
end;

procedure TContextFreeGrammTree.BuildFromGrammTree(view_node: TTreeNode;
  gramm_node: TGrammNode);
var child:TTreeNode;
    i:integer;
begin
  for i:=0 to gramm_node.GetChildsHigh do with gramm_node.GetChild(i) do
  begin
    child:=items.AddChild(view_node,GetName);
    child.ImageIndex:=ord(GetType);
    child.SelectedIndex:=child.ImageIndex;
    BuildFromGrammTree(child,gramm_node.GetChild(i));
  end;
end;

function TContextFreeGrammTree.NeedChanging(gramm_node,previous_gramm_node: TGrammNode):boolean;
var i,childs_high:integer;
begin
  result:=false;
  childs_high:=gramm_node.GetChildsHigh;
  with previous_gramm_node do
  if (gramm_node.GetName<>GetName)or
     (gramm_node.GetType<>GetType)or
     (gramm_node.GetChildsHigh<>GetChildsHigh)then
  begin
    result:=true;
    exit;
  end;
  for i:=0 to childs_high do
    if not result then
      result:=NeedChanging(gramm_node.GetChild(i),previous_gramm_node.GetChild(i));
end;

procedure TContextFreeGrammTree.ChangeFromGrammTree(view_node: TTreeNode;
  gramm_node,previous_gramm_node: TGrammNode);
var child,temp:TTreeNode;
    i,childs_high:integer;
begin
  childs_high:=gramm_node.GetChildsHigh;
  if view_node=nil then child:=items.GetFirstNode
  else child:=view_node.getFirstChild;
  for i:=0 to childs_high do with gramm_node.GetChild(i) do
  begin
    if  (gramm_node.GetType=G_ROOT) and
        (previous_gramm_node<>nil) and
        (i<=previous_gramm_node.GetChildsHigh) and
        (not NeedChanging(gramm_node.GetChild(i),previous_gramm_node.GetChild(i))) then
    else
    begin
      if child=nil then
        child:=items.AddChild(view_node,GetName)
      else
        child.Text:=GetName;
      child.ImageIndex:=ord(GetType);
      child.SelectedIndex:=child.ImageIndex;
      ChangeFromGrammTree(child,gramm_node.GetChild(i),nil);
    end;
    child:=child.getNextSibling;
  end;
  while(child<>nil)do
  begin
    temp:=child;
    child:=temp.getNextSibling;
    items.Delete(temp);
  end;
end;

procedure TContextFreeGrammTree.UpdateGrammSource;
var
  prod:TtreeNode;
  s:string;
begin
  if is_updating_tree then exit;
  prod:=Items.GetFirstNode;
  if prod=nil then s:=''
  else
  begin
    gramm_tree.Free;
    gramm_tree:=TgrammNode.Create(prod,nil,G_ROOT,'main node');
    gramm_tree.SaveGrammNode(s,0);
    //gramm_tree.Free;
  end;
  is_updating_gramm_source:=true;
  gramm_source.Text:=s;
  is_updating_gramm_source:=false;
end;

end.


