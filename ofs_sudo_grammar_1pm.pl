%%% Archivo: ofs_sudo_grammar_1pm.pl %%%%%%%%%%%%%%%%%
/*


ofs_program -> statement*

statement -> "const"  ident ("=" expr)? ";"?
expr -> ident | integer

ident -> [a-zA-Z_$][a-zA-Z_$0-9]* 
integer -> ([+-])?[0-9]+

null -~ semicolon
undefined -~ undefined

*/
%%%%%%%%%%%%%%%%%%%%%%%%% PROGRAM AST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- use_module(lexer).
ofs_program(OFSCodes, AstOFSPure) :-
    ofs_parser(AstOFSImpure, OFSCodes, []),
	purify(AstOFSImpure, AstOFSPure)
.

purify(AstOFSImpure, AstOFSPure) :-
   eliminate_null(AstOFSImpure, AstOFSPure)
.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GENERATOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
formated_time(FormattedTimeStamp) :- 
    get_time(TimeStamp),
    format_time(atom(FormattedTimeStamp), '%Y-%m-%d %T', TimeStamp).

options(splash, Splash) :- 
    formated_time(FormattedTimeStamp),
    format(atom(Splash), 'Generated by OFS compiler v 0.0 ~s', [FormattedTimeStamp]).

generator(StatementList, JSCodeString) :-
    options(splash, Splash),
    with_output_to(string(Str), (
        generate_line_comment(comment(Splash)),
        write_ast(StatementList),
        forall(member(Statement, StatementList), generate_statement(Statement))
    )),
    string_concat(Str, "\n", JSCodeString).

% Función para escribir el AST
write_ast(StatementList) :-
    format('/* AST: ~w */\n', [StatementList]).

% Generación de diferentes tipos de declaraciones y expresiones

generate_statement(declaration(Type, id(I), Expr)) :-
    generate_expression(Expr, ExprStr),
    format('~s ~s = ~s;\n', [Type, I, ExprStr]).
	
generate_statement(expr(Expr)) :-
    generate_expression(Expr, ExprStr),
    format('~s;\n', [ExprStr]).

generate_statement(import(Imports, From)) :-
    generate_imports(Imports, ImportsStr),
    format(atom(ImportStr), 'import ~s from "~s";\n', [ImportsStr, From]),
    write(ImportStr).

%%%%%% Caso por defecto para manejar AST no reconocidos %%%%%


generate_statement(S) :-
    write_unrecognized_statement(S).


generate_imports([Id], IdStr) :-
    generate_expression(Id, IdStr), !.
generate_imports(Ids, IdsStr) :-
    Ids = [_|_], % Asegurarse de que hay más de un elemento
    findall(IdStr, (member(Id, Ids), generate_expression(Id, IdStr)), IdStrs),
    atomic_list_concat(IdStrs, ', ', InnerIdsStr),
    format(atom(IdsStr), '{~s}', [InnerIdsStr]).	

%%
generate_expression(list(id(I), args(R)), ExprStr) :-
	process_args(R, Cadena),
    format(atom(ExprStr), ' ~s~s ', [I,Cadena]).
	
%%
generate_expression(conditional(expr(C), expr(I), expr(E)), ExprStr) :-
    generate_expression(C, CExprStr),
	generate_expression(I, IExprStr),
	generate_expression(E, EExprStr),
    format(atom(ExprStr), ' ~s? ~s : ~s', [CExprStr,IExprStr,EExprStr]).
	
	
%%% Manejo de llamadas a pipes y ofs funcions %%

generate_expression(pipe(Expr, Next), PipeStr) :-
    generate_expression(Expr, ExprStr),
    ( Next = [] ->
        PipeStr = ExprStr
    ; Next = pipe(_, _) ->
        generate_expression(Next, NextStr),
        format(atom(PipeStr), '~s.~s', [ExprStr, NextStr])
    ).	



generate_expression(iterate(First, Last), IterateStr) :-
    generate_expression(First, FirstStr),
    generate_expression(Last, LastStr),
    format(atom(IterateStr), 'iterate(~s, ~s)', [FirstStr, LastStr]).
	
generate_expression(filter(Expr), FilterStr) :-
    generate_expression(Expr, ExprStr),
    format(atom(FilterStr), 'filter(~s)', [ExprStr]).
	
generate_expression(cut(Arg), CutStr) :-
    generate_expression(Arg, ArgStr),
    format(atom(CutStr), 'cut(~s)', [ArgStr]).
	
generate_expression(map(Expr), MapStr) :-
    generate_expression(Expr, ExprStr),
    format(atom(MapStr), 'map(~s)', [ExprStr]).
	
	
% Manejo de llamadas a métodos
generate_expression(method(Object, id(Method)), MethodStr) :-
    generate_expression(Object, ObjectStr),
    format(atom(MethodStr), '~s.~s', [ObjectStr, Method]).

generate_expression(method(Object, MethodCall), MethodStr) :-
    MethodCall = method(_, _),
    generate_expression(Object, ObjectStr),
    generate_expression(MethodCall, MethodCallStr),
    format(atom(MethodStr), '~s.~s', [ObjectStr, MethodCallStr]).
	
generate_expression(method(Object, MethodCall), MethodStr) :-
    MethodCall = cal(_, _),
    generate_expression(Object, ObjectStr),
    generate_method_call(MethodCall, MethodCallStr),
    format(atom(MethodStr), '~s.~s', [ObjectStr, MethodCallStr]).
	
generate_expression(cal(Method, Args), CallStr) :-
    generate_expression(Method, MethodStr),
    generate_arguments(Args, ArgsStr),
    format(atom(CallStr), '~s(~s)', [MethodStr, ArgsStr]).
	
generate_expression(id(X), X) :- !.

generate_expression(literal(int(N)), Str) :- number_string(N, Str), !.

generate_expression(literal(str(S)), Str) :- format(atom(Str), '"~w"', [S]), !.  % Añadido manejo de literales string

generate_expression(Expr, ExprStr) :-
    Expr =.. [Op, Left, Right],
    generate_expression(Left, LeftStr),
    generate_expression(Right, RightStr),
    ( Op = arrow -> % Añadido manejo de expresiones de tipo flecha
        format(atom(ExprStr), '~s => ~s', [LeftStr, RightStr])
    ; format(atom(ExprStr), '~s ~s ~s', [LeftStr, Op, RightStr]) ).


generate_expression(Expr, ExprStr) :-
    Expr =.. [Op, Left, Right],
    generate_expression(Left, LeftStr),
    generate_expression(Right, RightStr),
    format(atom(ExprStr), '~s ~s ~s', [LeftStr, Op, RightStr]).	
	
	
% Generación de expresiones con paréntesis
generate_expression(expr_paren(InnerExpr), ExprStr) :-
    generate_expression(InnerExpr, InnerExprStr),
    format(atom(ExprStr), ' ( ~s )', [InnerExprStr]).
	

	
	


% Generación de la llamada al método
generate_method_call(cal(Method, Args), CallStr) :-
    generate_expression(Method, MethodStr),
    generate_arguments(Args, ArgsStr),
    format(atom(CallStr), '~s(~s)', [MethodStr, ArgsStr]).

% Generación de argumentos de la función
generate_arguments(Args, ArgsStr) :-
    maplist(generate_expression, Args, ArgsStrList),
    atomic_list_concat(ArgsStrList, ', ', ArgsStr).


% Función para manejar AST no reconocidos
write_unrecognized_statement(S) :-
    format('/* Unrecognized statement: ~w */\n', [S]).

% ... funciones para generar expresiones ...

generate_line_comment(comment(Comment)) :-
    format('// ~s\n', [Comment]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ofs_parser([]) --> [].
ofs_parser([S | RS]) --> (import_statement(S) ;statement(S) ; comment), ofs_parser(RS).
ofs_parser([]) --> spaces, !.


import_statement(import(Imports, From)) --> import, imported_symbols(Imports), from, string_literal(From).

imported_symbols([Ident|Idents]) --> left_curly, ident(Ident), imported_symbols_tail(Idents), right_curly.
imported_symbols([Ident]) --> ident(Ident).

imported_symbols_tail([Ident|Idents]) --> comma, ident(Ident), imported_symbols_tail(Idents).
imported_symbols_tail([]) --> [].


statement(declaration(Type, Ident, RS)) --> declaration_type(Type), ident(Ident), right_side(RS).
statement(expr(E)) --> spaces,expr(E),semicolon.
statement(null) --> semicolon.


comment --> spaces,"//", rest_of_line.

% Reconocimiento de comentarios de varias líneas
comment --> spaces, "/*", block_comment_content.

block_comment_content --> "*/", !.
block_comment_content --> [_], block_comment_content.

rest_of_line --> "\n", !.
rest_of_line --> [_], rest_of_line.



declaration_type(const) --> const.
declaration_type(let) --> let.
declaration_type(var) --> var.


right_side(E) --> assignment, expr(E),semicolon.
right_side(undefined) --> [].

% expr( I ) --> ident(I).
% expr(Num) --> number(Num).
expr(E) --> simple_expr(E).

% Iterable
expr(A) --> ofs_expression_iteration(A).
expr(pipe(N, A)) --> ident(N), pipe(A).

%%%% expr -> arrow_expr
expr(E) --> arrow_expr(E).

%%%% expr -> conditional_expression
expr(E) --> conditional_expression(E).

expr(declaration(Ident, E)) --> ident(Ident), assignment, expr(E).
%OFS
ofs_expression_iteration(pipe(cal(iterate(InitialExpr, expr(IterationExpr))),Z)) --> left_bracket, "*",spaces, number(InitialExpr), comma, arrow_expr(IterationExpr), right_bracket, pipe(Z).
ofs_expression_iteration(pipe(cal(iterate(IterId)),Z)) --> left_bracket, "*",spaces,  ident(IterId), right_bracket, pipe(Z).


ofs_expression(cal(filter(expr(FilterExpr)))) --> left_bracket, "?",spaces, arrow_expr(FilterExpr), right_bracket.
ofs_expression(cal(filter(FilterId))) --> left_bracket, "?",spaces, ident(FilterId), right_bracket.

ofs_expression(cal(map(expr(MapExpr)))) --> left_bracket, ">",spaces,arrow_expr(MapExpr), right_bracket.
ofs_expression(cal(map(MapId))) --> left_bracket, ">",spaces, ident(MapId), right_bracket.

ofs_expression(cal(cut(N))) --> left_bracket, "!",spaces, number(N), right_bracket.
ofs_expression(cal(cut(N))) --> left_bracket, "!",spaces, ident(N), right_bracket.


pipe([]) --> [].
pipe(pipe(Z,A)) --> pipe_op, ofs_expression(Z), pipe(A).
%%%% arrow_expr -> pipe_expr ("->" expr)*
arrow_expr(E) --> pipe_expr(P), arrow_expr_tail(P, E).
arrow_expr_tail(Prev, E) --> arrow_op, expr(Ex), { NewExpr = arrow(Prev, expr(Ex)) }, arrow_expr_tail(NewExpr, E).
arrow_expr_tail(E, E) --> [].

%%%%conditional_expression -> relational_expression "?" expression ":" expression
conditional_expression(conditional(expr(C),expr(I),expr(E))) --> factor(C), spaces, "?", spaces, expr(I), spaces, ":",spaces, expr(E).

%%%% simple_expr -> monom (("+"|"-")? monom)*
simple_expr(E) --> monom(M), simple_expr_tail(M, E).
simple_expr(E) --> monom(M), bool_expr_tail(M, E).
simple_expr_tail(Prev, E) --> add_sub_op(Op), monom(M), { NewExpr =.. [Op, Prev, M] }, simple_expr_tail(NewExpr, E).
simple_expr_tail(Prev, E) --> relational_operator(Op), monom(M), { NewExpr =.. [Op, Prev, M] }, simple_expr_tail(NewExpr, E).
simple_expr_tail(Prev, E) --> boolean_operator(Op), monom(M),{ NewExpr =.. [Op, Prev, M] }, simple_expr_tail(NewExpr, E).
simple_expr_tail(E, E) --> [].

%%%% boolean_expression -> relational_expression ( boolean_operator relational_expression)*
bool_expr_tail(Prev, E) --> relational_operator(Op), monom(M), { NewExpr =.. [Op, Prev, M] }, bool_expr_tail(NewExpr, E).
bool_expr_tail(Prev, E) --> boolean_operator(Op), monom(M),{ NewExpr =.. [Op, Prev, M] }, bool_expr_tail(NewExpr, E).
bool_expr_tail(E, E) -->[].

%%%% pipe_expr -> simple_expr (">>" expr)*
pipe_expr(E) --> simple_expr(S), pipe_expr_tail(S, E).
pipe_expr_tail(Prev, E) --> pipe_op, expr(Ex), { NewExpr = pipe(Prev, Ex) }, pipe_expr_tail(NewExpr, E).
pipe_expr_tail(E, E) --> [].

%%%% monom -> factor (("*"|"/")? factor)*
monom(M) --> factor(F), monom_tail(F, M).
monom_tail(Prev, M) --> mult_div_op(Op), factor(F), { NewExpr =.. [Op, Prev, F] }, monom_tail(NewExpr, M).
monom_tail(M, M) --> [].

%%%% factor -> cal | literal | "(" expr ")" | "-" expr | expr_list
factor(F) --> cal(F).
factor(literal(L)) --> literal(L).
factor(method(L,F)) --> literal(L),point_op, factor(F).
factor(expr_paren(E)) --> left_paren, expr(E), right_paren.
factor(neg_expr(E)) --> "-", expr(E).
factor(list(L,args(F))) --> ident(L), expr_list(F).

%%%% cal -> ident ("(" expr_sequence? ")")?
cal(cal(Id, Args)) --> ident(Id), left_paren, expr_sequence(Args), right_paren.
cal(Id) --> ident(Id).

%%%% expr_list -> "[" expr_sequence? "]"
expr_list([L|R]) --> left_bracket, optional_expr_sequence(L), right_bracket, expr_list(R).
expr_list([]) --> [].
optional_expr_sequence([]) --> [].
optional_expr_sequence(L) --> expr_sequence(L).

%%%% expr_sequence -> expr ("," expr)*
expr_sequence([E|Es]) --> expr(E), expr_sequence_tail(Es).
expr_sequence_tail([E|Es]) --> comma, expr(E), expr_sequence_tail(Es).
expr_sequence_tail([]) --> [].

%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTILS %%%%%%%%%%%%%%%%%%%%%%%
/*
Example:
?- eliminate_null( [const(x, int(666)), null, const(x, undefined), null], Ast).
Ast = [const(x, int(666)), const(x, undefined)]
*/
eliminate_null([], []).
eliminate_null([null | R], RWN) :- !, eliminate_null(R, RWN).
eliminate_null([S | R], [S | RWN] ) :- !, eliminate_null(R, RWN).

% Método para procesar la estructura y construir la cadena resultante
process_args(Args, Result) :-
    process_args_list(Args, ResultList),
    atomic_list_concat(ResultList, '', Result).

% Predicado auxiliar para procesar una lista de argumentos
process_args_list([], []).
process_args_list([Arg|Rest], [Value|Result]) :-
    process_arg(Arg, Value),
    process_args_list(Rest, Result).

% Predicado auxiliar para procesar un argumento
process_arg([literal(int(Value))], ValueStr) :-
    atomic_list_concat(['[', Value, ']'], ValueStr).
process_arg(_, '').
