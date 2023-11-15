%%% Archivo: test_parser.pl %%%%%%%%%%%%%%%%%
:- [ofs_sudo_grammar_1pm].

:- use_module(library(readutil)).

test_parser(Filename) :-
   read_file_to_codes(Filename, Codes, []),
   ofs_program(Codes, Ast),!,
   format('*** Parser of ~s was ok! ***\n', [Filename]),
   generator(Ast, JSCodeString),
   % Aquí puedes manejar la cadena JSCodeString como desees
   write(JSCodeString). % Por ejemplo, imprimirla en la consola.
test_parser(Filename) :-
   format('*** Parser of ~s was NOT ok! ***', [Filename])
.