Unit GrammTree;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, Menus, StdCtrls, GetNameForm, ImgList,

  RegExp,GrammSourceParser;

type

  TGrammNodeType=(
        G_TERM=0,
        G_NTERM,
        G_PROD,
        G_OR,
        G_AND,
        G_ANY_TIMES,
        G_ZERO_OR_ONE_TIMES,
        G_ONE_OR_MORE_TIMES,
        G_ROOT);

  const

  nodes_names:array[0..integer(G_ONE_OR_MORE_TIMES)] of string=
  (
    '',
    '',
    '',
    'Или',
    'И',
    'Любое число раз',
    'Ноль или один раз',
    'Один или более раз'
  );

type

  TGrammNode=class
  private
    node_type:TGrammNodeType;
    nterm_ref:TGrammNode;
    name:string;
    reg_exp:TDFA;
    childs:array of TGrammNode;
    corr_tree_view_node:Ttreenode;
    class procedure LoadGrammOr(source:TGrammSourceParser;parent:TGrammNode;log:TListBox);
    class procedure LoadGrammConcat(source:TGrammSourceParser;parent:TGrammNode;log:TListBox);
    class procedure LoadGrammFactor(source:TGrammSourceParser;parent:TGrammNode;log:TListBox);
    class procedure MoveChildsTo(source_node,target_node:TGrammNode);
    procedure AddChild(node:TGrammNode);
    procedure DeleteChild(child:TGrammNode);
    procedure ValidateLeftRecursion;
    procedure ClearProdFlag;
  public
    checked:boolean; //для нахождения неиспользуемых продукций
    prod_allready_used:boolean; //для контроля за леворекурсивностью
    property GetName:string read name;
    property GetType:TGrammNodeType read node_type;
    function GetChild(i:integer):TGrammNode;
    function GetChildsHigh:integer;
    procedure ValidateProdsNames;
    function SaveGrammNode(var s:string;col:integer):integer;
    procedure LoadGramm(source: TGrammSourceParser;log:TListBox);
    function FindProd(name:string):TGrammNode;
    function ValidateScript(script:string;var curr_char:integer;tree_view:TTreeView;
              build_parse_result:boolean;gramm_parse_result_parent:TTreeNode=nil):boolean;
    function ValidateSyntax(root:TGrammNode):boolean;
    constructor Create(first_child,treeview_node:TtreeNode;node_type:TGrammNodeType;name:string);overload;
    constructor Create(node_type:TGrammNodeType;name:string);                                    overload;
    procedure InitRefs(main_node:TGrammNode);
    destructor Destroy;override;
  end;

implementation

function TGrammNode.SaveGrammNode(var s:string;col:integer):integer;
var i,temp,h:integer;
    n:string;
begin
  result:=0;
  case node_type of
    G_ROOT:
      for i:=0 to High(childs)do childs[i].SaveGrammNode(s,col);
    G_TERM:
      begin
        n:=' '''+name+'''';
        s:=s+n;
        result:=Length(n);
      end;
    G_NTERM:
      begin
        n:=' '+name;
        s:=s+n;
        result:=Length(n);
      end;
    G_PROD:
      begin
        n:='  '+name+' :';
        s:=s+n;
        col:=length(n)-1;
        for i:=0 to High(childs) do childs[i].SaveGrammNode(s,col);
        s:=s+' ;'#13#10;
      end;
    G_AND:
      begin
        for i:=0 to High(childs) do
        begin
          temp:=childs[i].SaveGrammNode(s,col);
          inc(col,temp);
          inc(result,temp);
        end;
      end;
    G_OR:
      begin
        s:=s+' (';
        inc(col,2);
        result:=2;
        h:=High(childs);
        for i:=0 to h do
        begin
          childs[i].SaveGrammNode(s,col);
          s:=s+#13#10;
          s:=s+StringOfChar(' ',col);
          if(i<>h)then s:=s+'|'
          else s:=s+')';
        end;
      end;
    G_ANY_TIMES,
    G_ZERO_OR_ONE_TIMES,
    G_ONE_OR_MORE_TIMES:
      begin
        if (High(childs)>0) then
        begin
          s:=s+' (';
          for i:=0 to High(childs) do childs[i].SaveGrammNode(s,col+2);
          s:=s+' )';
          result:=2;
        end
        else
        begin
          if(childs[0].node_type=G_AND) then
          begin
            result:=3;
            s:=s+' (';
            inc(col,2);
          end;
          inc(result,childs[0].SaveGrammNode(s,col));
          if(childs[0].node_type=G_AND) then  s:=s+')';
        end;
        if node_type in[G_ANY_TIMES,G_ZERO_OR_ONE_TIMES,G_ONE_OR_MORE_TIMES]then
          inc(result);
        case node_type of
        G_ANY_TIMES:          s:=s+'*';
        G_ZERO_OR_ONE_TIMES:  s:=s+'?';
        G_ONE_OR_MORE_TIMES:  s:=s+'+';
        end;

      end;
    else assert(false);
  end;
end;

procedure TGrammNode.LoadGramm(source: TGrammSourceParser;log:TListBox);
var prod:TGrammNode;
    s:string;
begin
  while(source.NotEnd)do
  begin
    source.GetToken(T_NTERM,s);
    SetLength(childs,High(childs)+2);
    childs[High(childs)]:=TGrammNode.Create(G_PROD,s);
    prod:=childs[High(childs)];
    source.GetToken(T_COLON);
    LoadGrammOr(source,prod,log);
    source.GetToken(T_SEMICOLON);
  end
end;

class procedure TGrammNode.LoadGrammOr(source: TGrammSourceParser;
  parent: TGrammNode;log:TListBox);
var node:TGrammNode;
    is_or_stmt:boolean;
begin
  is_or_stmt:=false;
  node:=TGrammNode.Create(G_OR,nodes_names[ord(G_OR)]);
  parent.AddChild(node);
  LoadGrammConcat(source,node,log);
  while source.TestToken=T_VERTICAL do
  begin
    source.GetToken(T_VERTICAL);
    LoadGrammConcat(source,node,log);
    is_or_stmt:=true;
  end;
  if not is_or_stmt then
  begin
    MoveChildsTo(node,parent);
    parent.DeleteChild(node);
  end;
end;

class procedure TGrammNode.LoadGrammConcat(source: TGrammSourceParser;
  parent: TGrammNode;log:TListBox);
var node:TGrammNode;
    is_concat_stmt:boolean;
begin
  is_concat_stmt:=false;
  node:=TGrammNode.Create(G_AND,nodes_names[ord(G_AND)]);
  parent.AddChild(node);
  LoadGrammFactor(source,node,log);
  while source.TestToken in [T_TERM,T_NTERM,T_LEFT_PARENTH] do
  begin
    LoadGrammFactor(source,node,log);
    is_concat_stmt:=true;
  end;
  if not is_concat_stmt then
  begin
    MoveChildsTo(node,parent);
    parent.DeleteChild(node);
  end;
end;

class procedure TGrammNode.LoadGrammFactor(source: TGrammSourceParser;
  parent: TGrammNode;log:TListBox);
var node,temp:TGrammNode;
    s:string;
    t:TTokenType;
    g:TGrammNodeType;
begin
  node:=TGrammNode.Create(G_OR,nodes_names[ord(G_OR)]);
  parent.AddChild(node);
  t:=source.GetToken(s);
  case t of
  T_TERM:
  begin
    temp:=TGrammNode.Create(G_TERM,s);
    node.AddChild(temp);
    temp.reg_exp:=TDFA.Create;
    try
      temp.reg_exp.SetExpression(s);
    except
      on E:Exception do log.Items.Add('Ошибка в регулярном выражении (строка:'+inttostr(source.Line)+' столбец:'+inttostr(source.Col-1)+')! '+E.Message)
    end;
  end;
  T_NTERM:
    node.AddChild(TGrammNode.Create(G_NTERM,s));
  T_LEFT_PARENTH:
  begin
    LoadGrammOr(source,node,log);
    source.GetToken(T_RIGHT_PARENTH);
  end
  else raise Exception.Create('Синтаксическая ошибка (строка:'+inttostr(source.Line)+' столбец:'+inttostr(source.Col-1)+')!');
  end;
  if source.TestToken in [T_PLUS,T_MUL,T_QUESTION] then
  begin
    case source.TestToken of
    T_MUL:      g:=G_ANY_TIMES;
    T_PLUS:     g:=G_ONE_OR_MORE_TIMES;
    T_QUESTION: g:=G_ZERO_OR_ONE_TIMES;
    else assert(false);
    end;
    source.GetToken;
    node.name:=nodes_names[ord(g)];
    node.node_type:=g;
  end
  else
  begin
    MoveChildsTo(node,parent);
    parent.DeleteChild(node);
  end
end;

class procedure TGrammNode.MoveChildsTo(source_node,target_node:TGrammNode);
var i,h:integer;
begin
  h:=High(source_node.childs);
  for i:=0 to h do
    target_node.AddChild(source_node.childs[i]);
  SetLength(source_node.childs,0);
end;

procedure TGrammNode.ValidateProdsNames;
var i,c,h:integer;
begin
  h:=high(childs);
  for i:=0 to h do
    for c:=i to h do if(childs[c].name=childs[i].name)and (c<>i)then
      begin
        childs[c].corr_tree_view_node.Selected:=true;
        raise Exception.Create('Продукция "'+childs[i].name+'" уже существует!')
      end
end;

procedure TGrammNode.InitRefs(main_node:TGrammNode);
var i,h:integer;
begin
  if(node_type=G_NTERM)then
  begin
    nterm_ref:=main_node.FindProd(name);
    if (nterm_ref=nil) then
    begin
      corr_tree_view_node.Selected:=true;
      raise Exception.Create('Продукция "'+name+'" не найдена!')
    end;
  end;
  h:=high(childs);
  for i:=0 to h do childs[i].InitRefs(main_node);
end;

constructor TGrammNode.Create(first_child,treeview_node:TtreeNode;node_type:TGrammNodeType;name:string);
begin
  checked:=false;
  self.node_type:=node_type;
  self.nterm_ref:=nterm_ref;
  self.name:=name;
  corr_tree_view_node:=treeview_node;
  while(first_child<>nil)do
  begin
    setLength(childs,Length(childs)+1);
    childs[High(childs)]:=TGrammNode.Create(
        First_child.getFirstChild,First_child,
        TGrammNodeType(First_child.imageIndex),
        First_child.text );
    first_child:=first_child.getNextSibling;
  end
end;

constructor TGrammNode.Create(node_type:TGrammNodeType;name:string);
begin
  checked:=false;
  self.node_type:=node_type;
  self.name:=name;
end;

destructor TGrammNode.Destroy;
var
  h,i:integer;
begin
  h:=High(childs);
  for i:=0 to h do childs[i].Free;
  reg_exp.Free;
end;

function TGrammNode.FindProd(name:string):TGrammNode;
var
  h,i:integer;
begin
  result:=nil;
  h:=High(childs);
  for i:=0 to h do if(childs[i].name=name)then
  begin
    result:=childs[i];
    exit;
  end
end;

procedure TGrammNode.ValidateLeftRecursion;
var
  i,h:integer;
begin
  h:=High(childs);
  case node_type of
    G_TERM:begin end;
    G_NTERM:
      if nterm_ref.prod_allready_used then
      begin
        corr_tree_view_node.Selected:=true;
        raise Exception.Create('Леворекурсивные выражения не допустимы!');
      end
      else nterm_ref.ValidateLeftRecursion;
    G_PROD:
    begin
      prod_allready_used:=true;
      if High(childs)>-1 then
        childs[0].ValidateLeftRecursion;
      prod_allready_used:=false;
    end;
    G_AND,
    G_ANY_TIMES,
    G_ZERO_OR_ONE_TIMES,
    G_ONE_OR_MORE_TIMES:
      if High(childs)>-1 then
        childs[0].ValidateLeftRecursion;
    G_OR:
      for i:=0 to h do childs[i].ValidateLeftRecursion;
  else
    assert(false);
  end;
end;


function TGrammNode.ValidateScript(script:string;var curr_char:integer;tree_view:TTreeView;
  build_parse_result:boolean;gramm_parse_result_parent:TTreeNode=nil):boolean;
var
  t,h,i,last_char:integer;
  node:TTreeNode;
begin
  result:=false;
  case node_type of
    G_TERM:
      begin
        result:=reg_exp.Match(script,last_char,curr_char);
        if build_parse_result then
        begin
          node:=tree_view.Items.AddChild(gramm_parse_result_parent,Copy(script,curr_char,last_char-curr_char+1));
          node.ImageIndex:=0;
          node.SelectedIndex:=node.ImageIndex;
        end;
        if result then curr_char:=last_char+1;
      end;
    G_NTERM:
      begin
        t:=curr_char;
        result:=nterm_ref.ValidateScript(script,curr_char,tree_view,build_parse_result,gramm_parse_result_parent);
        if not result then curr_char:=t;
      end;
    G_PROD:
      begin
        if build_parse_result then
        begin
          node:=tree_view.Items.AddChild(gramm_parse_result_parent,name);
          node.ImageIndex:=2;
          node.SelectedIndex:=node.ImageIndex;
        end;
        if Pos('lxm',name)=1 then
        begin
          if build_parse_result then
          begin
            node.ImageIndex:=1;
            node.SelectedIndex:=node.ImageIndex;
          end;
          build_parse_result:=false;
        end;
        t:=curr_char;
        h:=High(childs);
        for i:=0 to h do
          if not childs[i].ValidateScript(script,curr_char,tree_view,build_parse_result,node) then
          begin
            result:=false;
            curr_char:=t;
            exit;
          end;
        result:=true;
      end;
    G_AND:
      begin
        t:=curr_char;
        h:=High(childs);
        for i:=0 to h do
          if not childs[i].ValidateScript(script,curr_char,tree_view,build_parse_result,gramm_parse_result_parent) then
          begin
            result:=false;
            curr_char:=t;
            exit;
          end;
        result:=true;
      end;
    G_OR:
      begin
        result:=false;
        t:=curr_char;
        h:=High(childs);
        for i:=0 to h do
          if childs[i].ValidateScript(script,curr_char,tree_view,false) then
          begin
            if build_parse_result then
            begin
              curr_char:=t;
              if not childs[i].ValidateScript(script,curr_char,tree_view,true,gramm_parse_result_parent) then
                assert(false);
            end;
            result:=true;
            exit;
          end;
        curr_char:=t;
      end;
    G_ANY_TIMES:
      begin
        result:=true;
        while(true)do
        begin
          t:=curr_char;
          h:=High(childs);
          for i:=0 to h do
            if not childs[i].ValidateScript(script,curr_char,tree_view,false) then
            begin
              curr_char:=t;
              exit;
            end;
          if t=curr_char then Exit;
          if (curr_char>t) and build_parse_result then
          begin
            curr_char:=t;
            for i:=0 to h do
              if not childs[i].ValidateScript(script,curr_char,tree_view,true,gramm_parse_result_parent) then
                assert(false);
          end
        end;
      end;
    G_ZERO_OR_ONE_TIMES:
      begin
        result:=true;
        t:=curr_char;
        h:=High(childs);
        for i:=0 to h do
          if not childs[i].ValidateScript(script,curr_char,tree_view,false) then
            curr_char:=t;
        if (curr_char>t) and build_parse_result then
        begin
          curr_char:=t;
          for i:=0 to h do
            if not childs[i].ValidateScript(script,curr_char,tree_view,true,gramm_parse_result_parent) then
              assert(false);
        end
      end;
    G_ONE_OR_MORE_TIMES:
      begin
        result:=false;
        while(true)do
        begin
          t:=curr_char;
          h:=High(childs);
          for i:=0 to h do
            if not childs[i].ValidateScript(script,curr_char,tree_view,false) then
            begin
              curr_char:=t;
              exit;
            end;
          if t=curr_char then Exit;
          if build_parse_result then
          begin
            curr_char:=t;
            for i:=0 to h do
              if not childs[i].ValidateScript(script,curr_char,tree_view,true,gramm_parse_result_parent) then
                assert(false);
          end;
          result:=true;
        end;
      end;
  end;
end;

function TGrammNode.ValidateSyntax(root:TGrammNode):boolean;
var
  s:string;
  i,h:integer;
begin
  case node_type of
    G_TERM,
    G_NTERM,
    G_ROOT:   result:=false;
  else result:=true;
  end;
  case node_type of
    G_TERM:
    begin
      reg_exp:=TDFA.Create;
      try
        reg_exp.SetExpression(name);
      except
        corr_tree_view_node.Selected:=true;
        raise;
      end;
      result:=true;
    end;
    G_NTERM:
    begin
      if nterm_ref<>nil then nterm_ref.checked:=true;
      result:=true;
    end;
    G_ROOT:
    begin
      h:=High(childs);
      result:=true;
      for i:=0 to h do result:=result and childs[i].ValidateSyntax(root)
    end;
  else
    begin
      if node_type=G_PROD then
      begin
        root.ClearProdFlag;
        ValidateLeftRecursion;
      end;
      h:=High(childs);
      if h=-1 then
      begin
        case node_type of
          G_PROD:      s:='Продукция не может быть пустой!';
          G_AND:       s:='Оператор "И" не может быть пустым!';
          G_OR:        s:='Оператор "ИЛИ" не может быть пустым!';
          G_ANY_TIMES: s:='Оператор "*" не может быть пустым!';
          G_ZERO_OR_ONE_TIMES: s:='Оператор "?" не может быть пустым!';
          G_ONE_OR_MORE_TIMES: s:='Оператор "+" не может быть пустым!';
        end;
        corr_tree_view_node.Selected:=true;
        raise Exception.Create(s);
      end
      else if (h=0)and((node_type=G_AND)or(node_type=G_OR)) then
      begin
        case node_type of
          G_AND:       s:='Оператор "И" должен содержать минимум два элемента!';
          G_OR:        s:='Оператор "ИЛИ" должен содержать минимум два элемента!';
        end;
        corr_tree_view_node.Selected:=true;
        raise Exception.Create(s);
      end
      else
        for i:=0 to h do result:=childs[i].ValidateSyntax(root)and result;
    end;
  end;
end;

function TGrammNode.GetChild(i: integer): TGrammNode;
begin
  result:=childs[i];
end;

function TGrammNode.GetChildsHigh: integer;
begin
  result:=High(childs);
end;

procedure TGrammNode.AddChild(node:TGrammNode);
var h:integer;
begin
  h:=High(childs);
  SetLength(childs,h+2);
  childs[h+1]:=node;
end;

procedure TGrammNode.DeleteChild(child: TGrammNode);
var i,h,c:integer;
begin
  h:=High(childs);
  for i:=0 to h do if childs[i]=child then
  begin
    c:=i;
    break;
  end;
  childs[i].Free;
  for i:=c+1 to h do childs[i-1]:=childs[i];
  SetLength(childs,h);
end;

procedure TGrammNode.ClearProdFlag;
var i,h:integer;
begin
  assert(node_type=G_ROOT);
  h:=High(childs);
  for i:=0 to h do childs[i].prod_allready_used:=false;
end;

end.
