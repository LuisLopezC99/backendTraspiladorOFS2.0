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
options(splash, 'Generated by OFS compiler v 0.0 11/13/2023 2pm').

generator(StatementList, JSCodeString) :-
    options(splash, Splash),
    with_output_to(string(Str), (
        generate_line_comment(comment(Splash)),
        forall(member(Statement, StatementList), generate_statement(Statement))
    )),
    string_concat(Str, "\n", JSCodeString). % Añadir un salto de línea final.

generate_statement(declaration(Type, id(I), undefined)) :- !,
    format('~s ~s = undefined;\n', [Type, I]).
generate_statement(declaration(Type, id(I), int(Num))) :- !,
    format('~s ~s = ~d;\n', [Type, I, Num]).
generate_statement(declaration(Type, id(I), id(K))) :- !,
    format('~s ~s = ~s;\n', [Type, I, K]).
generate_statement(S) :-
    format('Unrecognized statement: ~w\n', [S]).

generate_line_comment(comment(Comment)) :-
    format('// ~s\n', [Comment]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ofs_parser([]) --> [].
ofs_parser([S | RS]) --> (statement(S) ; comment), ofs_parser(RS).


statement(declaration(Type, Ident, RS)) --> declaration_type(Type), ident(Ident), right_side(RS).
statement(null) --> semicolon.

comment --> "//", rest_of_line.
rest_of_line --> "\n", !.
rest_of_line --> [_], rest_of_line.

declaration_type(const) --> const.
declaration_type(let) --> let.
declaration_type(var) --> var.


right_side(E) --> assignment, expr(E).
right_side(undefined) --> [].

expr( I ) --> ident(I).
expr(Num) --> integer(Num).

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

ident( id(Id) ) --> [X], { member(X, [36,95]);  char_type(X, alpha) }, ident_tail(Tail), { atom_codes(Id, [X|Tail]) }.

ident_tail([]) --> [].
ident_tail([X|Tail]) --> [X], { member(X, [36,95]); char_type(X, alpha) }, ident_tail(Tail).

integer( int(666) ) --> "666".

const --> spaces, "const", space, spaces.
let --> spaces, "let", space, spaces.
var --> spaces, "var", space, spaces.

space --> " ";"\t";"\n";"\r".

assignment --> spaces, "=", spaces.

semicolon --> spaces, ";", spaces.

spaces --> space, spaces.
spaces --> [].



