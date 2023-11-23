%%% Archivo: ofs_grammar.pl %%%%%%%%%%%%%%%%%


:- use_module(library(readutil)).
:- use_module(generator).
:- use_module(utils).
:- use_module(parser).

ofs_grammar(Filename) :-
   read_file_to_codes(Filename, Codes, []),
   ofs_program(Codes, Ast),!,
   format('*** Parser of ~s was ok! ***\n', [Filename]),
   generator(Ast, JSCodeString),
   % Aquí puedes manejar la cadena JSCodeString como desees
   write(JSCodeString). % Por ejemplo, imprimirla en la consola.
ofs_grammar(Filename) :-
   format('*** Parser of ~s was NOT ok! ***', [Filename])
.

ofs_program(OFSCodes, AstOFSPure) :-
    ofs_parser(AstOFSImpure, OFSCodes, []),
	eliminate_null(AstOFSImpure, AstOFSPure)
.