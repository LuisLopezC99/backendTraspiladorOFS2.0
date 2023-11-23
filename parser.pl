/* 
University: Universidad Nacional
School: Escuela de Informatica
Course: Paradigmas de Programación EIF 400
Semester: 2 Year: 2023
Team 02-1pm 
Members:
Luis Lopez Castro id: 402420889
Anderson Mora Aguero id: 115600170
David Morales Hidalgo id: 116300616
Alberto Aguero Herdocia id: 118450651
Project: OneFlowStream (OFS)
SubProyect: BackEndTraspiler
File: parser.pl 
*/
%%%%%%%%%%%%%%%%%%%%%%%%% MODULE_PARSER %%%%%%%%%%%%%%%%%%%%
:- module(parser, [
    
	ofs_parser/3,
    import_statement/3,
    imported_symbols/3,
	imported_symbols_tail/3,
	
    statement/3,
	
    comment/2,
    block_comment_content/2,
    rest_of_line/2,
	
    declaration_type/3,
    right_side/3,
	
    expr/3,
    ofs_expression_iteration/3,
    ofs_expression/3,
    pipe/3,
    arrow_expr/3,
    simple_expr/3,
    pipe_expr/3,
	
    monom/3,
    factor/3
]).

:- use_module(lexer).
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
expr(list(args(ListExpr))) --> expr_list(ListExpr).
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
ofs_expression_iteration(pipe(iterate(InitialExpr, expr(IterationExpr)),Z)) --> left_bracket, "*",spaces, number(InitialExpr), comma, arrow_expr(IterationExpr), right_bracket, pipe(Z).
ofs_expression_iteration(pipe(iterate(IterId),Z)) --> left_bracket, "*",spaces,  ident(IterId), right_bracket, pipe(Z).


ofs_expression(filter(expr(FilterExpr))) --> left_bracket, "?",spaces, arrow_expr(FilterExpr), right_bracket.
ofs_expression(filter(FilterId)) --> left_bracket, "?",spaces, ident(FilterId), right_bracket.

ofs_expression(map(expr(MapExpr))) --> left_bracket, ">",spaces,arrow_expr(MapExpr), right_bracket.
ofs_expression(map(MapId)) --> left_bracket, ">",spaces, ident(MapId), right_bracket.

ofs_expression(cut(N)) --> left_bracket, "!",spaces, number(N), right_bracket.
ofs_expression(cut(N)) --> left_bracket, "!",spaces, ident(N), right_bracket.


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
expr_list([L|R]) --> left_bracket, optional_expr_sequence(L), right_bracket, { L \= [] }, expr_list(R),!.
expr_list([L]) --> left_bracket, optional_expr_sequence(L), right_bracket, { L = [] }, !.
expr_list([]) --> [].


optional_expr_sequence([]) --> [].
optional_expr_sequence(L) --> expr_sequence(L).

%%%% expr_sequence -> expr ("," expr)*
expr_sequence([E|Es]) --> expr(E), expr_sequence_tail(Es).
expr_sequence_tail([E|Es]) --> comma, expr(E), expr_sequence_tail(Es).
expr_sequence_tail([]) --> [].
