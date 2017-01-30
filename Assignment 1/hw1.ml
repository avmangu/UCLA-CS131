(* hw1.ml *)

(* helper function *)
let rec is_element a lst =
	match lst with
	[] ->  false
	| h::t -> if a = h then true else is_element a t;;

(* 1. Write a function subset a b that returns true iff a is a subset of b *)	
let rec subset a b = 
	match a with
	[] -> true
	| h::t -> if (is_element h b) = false then false
	          else subset t b;;

(* 2. Write a function equal_sets a b that returns true iff the represented sets are equal *)
let equal_sets a b =
	if (subset a b) = true && (subset b a) = true then true
	else false;;

(* 3. Write a function set_union a b that returns a list representing a unions b *)
(* duplicates? *)
let set_union a b = a@b;;

(* 4. Write a function set_intersection a b that returns a list representing a intersects b *)
let rec set_intersection a b =
    match a with
    [] -> []
    | h::t -> if (is_element h b) = true then h::(set_intersection t b)
              else set_intersection t b;;

(* 5. Write a function set_diff a b that returns a list representing a-b *)
let rec set_diff a b =
	match a with
	[] -> []
	| h::t -> if (is_element h b) = true then set_diff t b
	          else h::(set_diff t b);;

(* 6. Write a function computed_fixed_point eq f x that returns the computed fixed point of f w.r.t x *)
let rec computed_fixed_point eq f x =
	if (eq (f x) x) = true then x
    else computed_fixed_point eq f (f x);;
    (* What if we cannot find the fixed point? *)

(* 7. Write a function computed_periodic_point eq f p x that returns the computed periodic point for f with period p and with respect to x *)
let rec helper f p x =
	if p = 1 then (f x)
    else helper f (p-1) (f x);;

let rec computed_periodic_point eq f p x =
	if p = 0 then x
    else if p = 1 then (computed_fixed_point eq f x)
    else if (eq (helper f p x) x) then x
    else (computed_periodic_point eq f p (f x));; 

(* 8. Write a function while_away s p x *)
let rec while_away s p x =
	if (p x) = false then []
	else x::(while_away s p (s x));;

(* 9. Write a function rle_decode lp that decodes a list of pairs lp in run-length encoding form. *)
let rec pair_decode n c lst =
	if n = 0 then lst
    else (pair_decode (n-1) c lst@[c]);;

let rec rle_decode lp = 
	match lp with
	[] -> []
	| h::t -> match h with (n,c) -> (pair_decode n c [])@(rle_decode t);;

(* 10. Write a function filter_blind_alleys g that returns a copy of the grammar g with all blind alley rules moved. *)
(* This function should preserve the order of tules. *)

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

let is_terminal_symb symb t_symb_lst =
	match symb with
	T _ -> true
	| N s -> is_element s t_symb_lst;;

let rec check_rules rules t_symb_lst =
	match rules with
	[] -> true
	| h::t -> if (is_terminal_symb h t_symb_lst) then (check_rules t t_symb_lst)
			  else false;;

let rec build_grammar grammar t_symb_lst =
	match grammar with
	[] -> t_symb_lst
	| (a, rule)::t -> if (check_rules rule t_symb_lst) && not (is_element a t_symb_lst) then (build_grammar t (a::t_symb_lst))
					  else (build_grammar t t_symb_lst);;

let build_grammar_wrap (orig_lst, t_symb_lst) =
	orig_lst, (build_grammar orig_lst t_symb_lst);;

let snd_equal_set (x1, y1) (x2, y2) = equal_sets y1 y2;;

let rec rule_filter rules t_symb_lst new_rules =
	match rules with
	[] -> new_rules
	| (a,r)::t -> if (check_rules r t_symb_lst) then (rule_filter t t_symb_lst (new_rules@[(a,r)]))
				  else (rule_filter t t_symb_lst new_rules);;

let filter_blind_alleys g =
	(fst g), (rule_filter (snd g) (snd (computed_fixed_point snd_equal_set build_grammar_wrap ((snd g), []))) []);;

