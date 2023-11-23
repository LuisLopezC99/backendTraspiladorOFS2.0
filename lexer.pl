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
File: lexer.pl 
*/
%%%%%%%%%%%%%%%%%%% module_lexer %%%%%%%%%%%%%%%%%%%%
:- module(lexer, [
	ident/3, ident_tail/3,
    const//0, let//0, var//0,
    import//0, from//0,
    assignment//0, semicolon//0, comma//0,
    left_bracket//0, right_bracket//0,
    left_curly//0, right_curly//0,
    left_paren//0, right_paren//0,
    single_quote//0, double_quote//0,
    mult_div_op/3, add_sub_op/3,
    relational_operator/3,  
    boolean_operator/3,
    pipe_op//0, arrow_op//0, point_op//0,
    space//0, spaces//0,
    literal/3, string_literal/3,
    single_quoted_string/3, double_quoted_string/3,
    string_chars/3,
	number/3, optional_sign/3,
    digits/3, digit/3,
    boolean/3
]).

ident(id(X)) --> [C], { char_type(C, alpha) }, ident_tail(Tail), { atom_codes(X, [C|Tail]) }.
ident_tail([X|Tail]) --> [X], { member(X, [36,95]); char_type(X, alnum) }, ident_tail(Tail).
ident_tail([]) --> [].


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
mult_div_op('%') --> spaces,"%", spaces, !.
add_sub_op('+') --> spaces,"+", spaces, !.
add_sub_op('-') --> spaces,"-", spaces, !.
relational_operator('>=') --> spaces,">=", spaces, !.
relational_operator('<=') --> spaces,"<=", spaces, !.
relational_operator('<') --> spaces,"<", spaces, !.
relational_operator('>') --> spaces,">", spaces, !.
relational_operator('===') --> spaces,"===", spaces, !.
relational_operator('==') --> spaces,"==", spaces, !.
relational_operator('!=') --> spaces,"!=", spaces, !.
boolean_operator('&&') --> spaces,"&&", spaces, !.
boolean_operator('||') --> spaces,"||", spaces, !.

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