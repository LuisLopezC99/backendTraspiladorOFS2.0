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
	
	
generate_expression(id(X), X) :- !.

generate_expression(literal(int(N)), Str) :- number_string(N, Str), !.

generate_expression(literal(str(S)), Str) :- format(atom(Str), '"~w"', [S]), !.  % Añadido manejo de literales string

generate_expression(Expr, ExprStr) :-
    Expr =.. [Op, Left, Right],
    generate_expression(Left, LeftStr),
    generate_expression(Right, RightStr),
    ( Op = arrow -> % Añadido manejo de expresiones de tipo flecha
        format(atom(ExprStr), '~s --> ~s', [LeftStr, RightStr])
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
	
	
% Manejo de llamadas a métodos
generate_expression(method(Object, MethodCall), MethodStr) :-
    generate_expression(Object, ObjectStr),
    generate_method_call(MethodCall, MethodCallStr),
    format(atom(MethodStr), '~s.~s', [ObjectStr, MethodCallStr]).

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

%%%% expr -> arrow_expr
expr(E) --> arrow_expr(E).

%%%% arrow_expr -> pipe_expr ("->" expr)*
arrow_expr(E) --> pipe_expr(P), arrow_expr_tail(P, E).
arrow_expr_tail(Prev, E) --> arrow_op, expr(Ex), { NewExpr = arrow(Prev, Ex) }, arrow_expr_tail(NewExpr, E).
arrow_expr_tail(E, E) --> [].

%%%% simple_expr -> monom (("+"|"-")? monom)*
simple_expr(E) --> monom(M), simple_expr_tail(M, E).
simple_expr_tail(Prev, E) --> add_sub_op(Op), monom(M), { NewExpr =.. [Op, Prev, M] }, simple_expr_tail(NewExpr, E).
simple_expr_tail(E, E) --> [].

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
factor(F) --> expr_list(F).

%%%% cal -> ident ("(" expr_sequence? ")")?
cal(cal(Id, Args)) --> ident(Id), left_paren, expr_sequence(Args), right_paren.
cal(Id) --> ident(Id).

%%%% expr_list -> "[" expr_sequence? "]"
expr_list(L) --> left_bracket, optional_expr_sequence(L), right_bracket.
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

%%%%%%%%%%%%%%%%%%%%%%%%%%% TOKENIZER = LEXER %%%%%%%%%%%%%%%%%%%%%

ident(id(X)) --> [C], { char_type(C, alpha) }, ident_tail(Tail), { atom_codes(X, [C|Tail]) }.
ident_tail([]) --> [].
ident_tail([X|Tail]) --> [X], { member(X, [36,95]); char_type(X, alnum) }, ident_tail(Tail).


const --> spaces, "const", space, spaces.
let --> spaces, "let", space, spaces.
var --> spaces, "var", space, spaces.



% Palabras clave para import_statement
import --> spaces, "import", spaces.
from --> spaces, "from", spaces.

assignment --> spaces, "=", spaces.
semicolon --> spaces, ";", spaces.
comma --> spaces, ",", spaces.
left_bracket --> spaces, "[", spaces.
right_bracket --> spaces, "]", spaces.
left_curly --> spaces, "{", spaces.
right_curly --> spaces, "}", spaces.
left_paren --> spaces, "(", spaces.
right_paren --> spaces, ")", spaces.
single_quote --> spaces,"'", spaces.
double_quote --> spaces,"\"", spaces.
mult_div_op('*') --> spaces,"*", spaces, !.
mult_div_op('/') --> spaces,"/", spaces, !.
add_sub_op('+') --> spaces,"+", spaces, !.
add_sub_op('-') --> spaces,"-", spaces, !.
pipe_op --> spaces,">>", spaces.
arrow_op --> spaces,"->", spaces.
point_op --> ".".

space --> " ";"\t";"\n";"\r".
spaces --> space, spaces.
spaces --> [].

literal(Id) --> ident(Id).
literal(Num) --> number(Num).
literal(Bool) --> boolean(Bool).
literal(null) --> "null".
literal(undefined) --> "undefined".
literal(str(Str)) --> string_literal(Str).


string_literal(Str) --> single_quoted_string(Str).
string_literal(Str) --> double_quoted_string(Str).

single_quoted_string(Str) --> single_quote, string_chars(StrChars), single_quote, { atom_chars(Str, StrChars) }.
double_quoted_string(Str) --> double_quote, string_chars(StrChars), double_quote, { atom_chars(Str, StrChars) }.


string_chars([Char|Chars]) --> [Char], { Char \= '\'' }, string_chars(Chars).
string_chars([]) --> [].

number(int(N)) --> optional_sign(Sign), digits(Ds), 
                   { maplist(char_code, CharsDs, Ds), 
                     (Sign = '', number_chars(N, CharsDs);
                      Sign \= '', number_chars(N, [Sign|CharsDs])) }.
number(int(N)) --> digits(Ds), 
                   { maplist(char_code, CharsDs, Ds), 
                     number_chars(N, CharsDs) }.

optional_sign('-') --> spaces,"-", spaces, !.
optional_sign('+') --> spaces,"+", spaces, !.
optional_sign('') --> [].

digits([D|T]) --> digit(D), digits(T).
digits([D]) --> digit(D).

digit(D) --> [D], { char_type(D, digit) }.


boolean(true) --> "true".
boolean(false) --> "false".