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
File: utils.pl 
*/
%%%%%%%%%%%%%%%%%%%%%%%%% MODULE_UTILS%%%%%%%%%%%%%%%%%%%%
:- module(utils, [
    eliminate_null/2,
	process_args/2,
	process_args_list/2,
	process_arg/2
]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTILS %%%%%%%%%%%%%%%%%%%%%%%
% Purifies by eliminating nulls
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