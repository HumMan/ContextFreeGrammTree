unit GrammSourceParser;
interface

  type
    TTokenType=(T_TERM,
              T_NTERM,
              T_COLON,           //':'
              T_LEFT_PARENTH,   //'('
              T_RIGHT_PARENTH,  //')'
              T_VERTICAL,       //'|'
              T_SEMICOLON,      //';'
              T_MUL,            //'*'
              T_PLUS,           //'+'
              T_QUESTION        //'?'
              );


    TGrammSourceParser=class
    private
      curr_line_index,
      curr_char,
      curr_line:integer;
      gramm:string;
      procedure SkipSpaces(source:string;var curr_char,curr_line:integer);
      function FGetCol:integer;
    public
      property Line:integer read curr_line;
      property Col:integer read FGetCol;
      procedure StartParsing(use_gramm:string);
      function GetToken(var s:string):TTokenType;overload;
      procedure GetToken(token_type:TTokenType;var s:string);overload;
      procedure GetToken(token_type:TTokenType);overload;
      procedure GetToken;overload;
      function GetNTerminal:string;
      function TestToken:TTokenType;
      function NotEnd:boolean;
    end;

implementation
uses SysUtils;

procedure TGrammSourceParser.StartParsing(use_gramm:string);
begin
  gramm:=use_gramm;
  curr_char:=1;
  curr_line:=0;
  curr_line_index:=0;
end;

procedure TGrammSourceParser.SkipSpaces(source:string;var curr_char,curr_line:integer);
var l:integer;
begin
  l:=Length(source);
  while(curr_char<=l)do
    case source[curr_char] of
    #13:
      if (curr_char<l)and(source[curr_char+1]=#10)then
      begin
        inc(curr_char,2);
        inc(curr_line);
        curr_line_index:=curr_char-1;
      end;
    #9,' ':inc(curr_char)
    else break;
    end;
end;

function TGrammSourceParser.GetNTerminal:string;
var t,l:integer;
begin
  l:=length(gramm);
  t:=curr_char;
  while (curr_char<=l) and ( gramm[curr_char]  in ['a'..'z','A'..'Z','0'..'9','_'])do
    inc(curr_char);
  result:=copy(gramm,t,curr_char-t);
end;

procedure TGrammSourceParser.GetToken(token_type:TTokenType);
var s:string;
begin
  if GetToken(s)<>token_type then
    raise Exception.Create('Ожидался другой токен (строка:'+inttostr(curr_line)+' столбец:'+inttostr(curr_char-1)+')!');
end;

procedure TGrammSourceParser.GetToken;
var s:string;
begin
  GetToken(s);
end;

procedure TGrammSourceParser.GetToken(token_type:TTokenType;var s:string);
begin
  if GetToken(s)<>token_type then
    raise Exception.Create('Ожидался другой токен (строка '+inttostr(curr_line)+')!');
end;

function TGrammSourceParser.GetToken(var s:string):TTokenType;
var t:integer;
begin
  SkipSpaces(gramm,curr_char,curr_line);
  if curr_char>length(gramm) then
    raise Exception.Create('Неожиданный конец файла (строка '+inttostr(curr_line)+')!');
  case gramm[curr_char] of
  'a'..'z','A'..'Z','0'..'9','_':
  begin
    result:=T_NTERM;
    s:=GetNTerminal;
  end;
  '''':
  begin
    result:=T_TERM;
    inc(curr_char);
    t:=curr_char;
    while not(((gramm[curr_char-1]<>'\')and(gramm[curr_char]=''''))or (gramm[curr_char]=#13)) do
      inc(curr_char);
    s:=copy(gramm,t,curr_char-t);
    if gramm[curr_char]='''' then inc(curr_char)
    else
      raise Exception.Create('Недопустимый символ в описании терминала (строка '+inttostr(curr_line)+')!');
  end;
  ':','(',')','|',';','*','+','?':
  begin
    case gramm[curr_char] of
    ':':result:=T_COLON;
    '(':result:=T_LEFT_PARENTH;
    ')':result:=T_RIGHT_PARENTH;
    '|':result:=T_VERTICAL;
    ';':result:=T_SEMICOLON;
    '*':result:=T_MUL;
    '+':result:=T_PLUS;
    '?':result:=T_QUESTION;
    end;
    inc(curr_char);
  end;
  else
    raise Exception.Create('Недопустимый символ ('''+gramm[curr_char]+''') в файле грамматики (строка '+inttostr(curr_line)+')!');
  end;
  SkipSpaces(gramm,curr_char,curr_line);
end;

function TGrammSourceParser.NotEnd: boolean;
begin
  result:=curr_char<=length(gramm);
end;

function TGrammSourceParser.TestToken: TTokenType;
var tl,tc:integer;
    s:string;
begin
  tl:=curr_line;
  tc:=curr_char;
  result:=GetToken(s);
  curr_char:=tc;
  curr_line:=tl;
end;

function TGrammSourceParser.FGetCol: integer;
begin
  result:=curr_char-curr_line_index;
end;

end.
