%%%%%%%%%%%% Matching %%%%%%%%%%%%

%	At the signal level, 1 (a signal-on of duration 1) represents dih
%	111 (a signal-on of duration 3) represents dah 
%	0 (a signal-off of duration 1) separates dihs from dahs within a letter
%	000 (signal-off of duration 3) represents the boundary between two letters
%	0000000 (signal-off of duration 7) represent the space between words
match([1], '.').
%	11: the original signals could have been either 1 or 111.
match([1,1], '.').
match([1,1|_], '-').
match([0], '*'). %separates
%	00: could have been either 0 or 000 in the original data
match([0,0], '*').
match([0,0], '^').
match([0,0,0], '^').
%	0000: must have been 000
match([0,0,0,0], '^').
%	00000: either 000 or 0000000
match([0,0,0,0,0], '^').
match([0,0,0,0,0|_], '#'). % CHECK THIS AGAIN! 6 or 8

%%%%%%%%%%%% Find consecutives %%%%%%%%%%%%

match_consecutives(LstA, LstB, Result) :- 
	find_consecutives(LstA, LstB, Lst), match(Lst, Result).

find_consecutives([], [], []).
find_consecutives([1|T1], LstB, [1|T2]) :- find_1_consecutives(T1, LstB, T2).
find_consecutives([0|T1], LstB, [0|T2]) :- find_0_consecutives(T1, LstB, T2).

find_1_consecutives([1|Succ1], LstB, [1|Succ2]) :- 
	find_1_consecutives(Succ1, LstB, Succ2), !.
find_1_consecutives(T, T, []).

find_0_consecutives([0|Succ1], LstB, [0|Succ2]) :- 
	find_0_consecutives(Succ1, LstB, Succ2), !.
find_0_consecutives(T, T, []).

%%%%%%%%%%%% Remove the *s which denotes the separations within a letter

remove_separates([], []).
remove_separates(['*'|T], M) :- remove_separates(T, M), !.
remove_separates([H|T1], [H|T2]) :- remove_separates(T1, T2), !.

%%%%%%%%%%%% signal_morse %%%%%%%%%%%%

signal_morse_helper([], []).
signal_morse_helper(L, [H|T]) :- 
	match_consecutives(L, Remain, H), signal_morse_helper(Remain, T).

signal_morse(L, M) :- signal_morse_helper(L, R), remove_separates(R, M).

%%%%%%%%%%%% 

morse(a, [.,-]).           % A
morse(b, [-,.,.,.]).	   % B
morse(c, [-,.,-,.]).	   % C
morse(d, [-,.,.]).	   % D
morse(e, [.]).		   % E
morse('e''', [.,.,-,.,.]). % É (accented E)
morse(f, [.,.,-,.]).	   % F
morse(g, [-,-,.]).	   % G
morse(h, [.,.,.,.]).	   % H
morse(i, [.,.]).	   % I
morse(j, [.,-,-,-]).	   % J
morse(k, [-,.,-]).	   % K or invitation to transmit
morse(l, [.,-,.,.]).	   % L
morse(m, [-,-]).	   % M
morse(n, [-,.]).	   % N
morse(o, [-,-,-]).	   % O
morse(p, [.,-,-,.]).	   % P
morse(q, [-,-,.,-]).	   % Q
morse(r, [.,-,.]).	   % R
morse(s, [.,.,.]).	   % S
morse(t, [-]).	 	   % T
morse(u, [.,.,-]).	   % U
morse(v, [.,.,.,-]).	   % V
morse(w, [.,-,-]).	   % W
morse(x, [-,.,.,-]).	   % X or multiplication sign
morse(y, [-,.,-,-]).	   % Y
morse(z, [-,-,.,.]).	   % Z
morse(0, [-,-,-,-,-]).	   % 0
morse(1, [.,-,-,-,-]).	   % 1
morse(2, [.,.,-,-,-]).	   % 2
morse(3, [.,.,.,-,-]).	   % 3
morse(4, [.,.,.,.,-]).	   % 4
morse(5, [.,.,.,.,.]).	   % 5
morse(6, [-,.,.,.,.]).	   % 6
morse(7, [-,-,.,.,.]).	   % 7
morse(8, [-,-,-,.,.]).	   % 8
morse(9, [-,-,-,-,.]).	   % 9
morse(., [.,-,.,-,.,-]).   % . (period)
morse(',', [-,-,.,.,-,-]). % , (comma)
morse(:, [-,-,-,.,.,.]).   % : (colon or division sign)
morse(?, [.,.,-,-,.,.]).   % ? (question mark)
morse('''',[.,-,-,-,-,.]). % ' (apostrophe)
morse(-, [-,.,.,.,.,-]).   % - (hyphen or dash or subtraction sign)
morse(/, [-,.,.,-,.]).     % / (fraction bar or division sign)
morse('(', [-,.,-,-,.]).   % ( (left-hand bracket or parenthesis)
morse(')', [-,.,-,-,.,-]). % ) (right-hand bracket or parenthesis)
morse('"', [.,-,.,.,-,.]). % " (inverted commas or quotation marks)
morse(=, [-,.,.,.,-]).     % = (double hyphen)
morse(+, [.,-,.,-,.]).     % + (cross or addition sign)
morse(@, [.,-,-,.,-,.]).   % @ (commercial at)

% Error.
morse(error, [.,.,.,.,.,.,.,.]). % error - see below

% Prosigns.
morse(as, [.,-,.,.,.]).          % AS (wait A Second)
morse(ct, [-,.,-,.,-]).          % CT (starting signal, Copy This)
morse(sk, [.,.,.,-,.,-]).        % SK (end of work, Silent Key)
morse(sn, [.,.,.,-,.]).          % SN (understood, Sho' 'Nuff)

%%%%%%%%%%%% translate the list of morse code to the list of letters %%%%%%%%%%%%

translate_helper2(LH, LT, R) :- append(X,['^'|LT],LH), morse(R,X).
translate_helper2(LH, [], R) :- morse(R, LH).

translate_helper([],[]).
translate_helper(MorseWord, [H|T]) :- 
	translate_helper2(MorseWord, X, H), translate_helper(X, T).

translate([], []).
translate(MorseCode, Raw) :- translate_helper(MorseCode, Raw).
translate(MorseCode, Raw) :- 
	append(Word, ['#'|Words], MorseCode),
	translate_helper(Word, RawWord),
	translate(Words, RawWords),
	append(RawWord, ['#'|RawWords], Raw).

% 	???	However, signal_message/2 should succeed only for disambiguated signals 
%		that correspond to a valid Morse code message.

%	As a special case, if your signal_message/2 implementation finds a word, 
%	followed by zero or more spaces, followed by an error token, it should omit 
%	the word, the spaces, and the error token; it should then start scanning again 
%	after the omitted tokens, looking for further errors.

%%%%%%%%%%%% Deleting %%%%%%%%%%%%

%	Empty list
delete_word([],[]).
%	If there is no 'error' token in the list, then we just keep it unchanged.
delete_word(Raw, Raw) :- \+ member('error', Raw).
%	If the first one is '#'.
delete_word(['#'|T1],['#'|T2]) :- delete_word(T1,T2).
%	If the first one is 'error'.
delete_word(['error'|T1],['error'|T2]) :- delete_word(T1,T2), !.
delete_word(Raw, M) :- 
    append(H,['error'|T], Raw),
    \+ member('error',H),
    get_word(H,HD), % get the last word 
    delete_word(T,Rest), % recursive call
    append(HD,Rest,M). % append two parts to get the resulting list M

%%%%%%%%%%%% Get the last word that we might want to delete %%%%%%%%%%%%

%	If there is no '#' in the list, then we return emply list
get_word(List, []) :- \+ member('#', List).
%	The last element of the list is not '#':
get_word(List, Result) :- 
	% get the last element, which is not '#'
    append(_,[Last], List), Last\='#', 
    % find the elements before and after '#'
    append(H,['#'|T], List),
    % No '#' remains in the rest of the list
    \+ member('#',T),
    append(H,['#'], Result). % get the result
get_word(List, Result) :- 
	% get the last element, which is '#'
    append(H, [Last], List), Last='#',
    get_word(H, Result).

%%%%%%%%%%%% signal_message %%%%%%%%%%%%

signal_message([], []).
signal_message(L, M) :- 
	signal_morse(L, MorseCode), % convert to Morse Code
	translate(MorseCode, Raw),  % convert to letters, containing 'error's
	delete_word(Raw, M). % remove the errors and corresponding words
