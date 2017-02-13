type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(* Warm up *)

let rec convert_rules rules lst x = 
  match rules with
  | [] -> lst (* the rule list is exhausted *)
  | rules_head :: rules_tail -> 
      match rules_head with
      | (lhs, rhs) -> 
  		    if lhs = x then convert_rules rules_tail (lst@[rhs]) x
          else
             convert_rules rules_tail lst x


let convert_grammar gram1 = match gram1 with 
  (* the first item in gram1 is the start symbol
     the second item are the list of rules that need to be converted into HW2 form *)
  | (start_symb, rules) -> (start_symb, (convert_rules rules []))

(* Write a function that returns a matcher for the grammar*)
let append_dev prev_dev lhs rule =
  prev_dev @ [(lhs, rule)]

(* Buggy!!
let rec and_matcher orig_rules pick_rules acceptor derivation fragment = 
  match pick_rules with
  | [] -> acceptor derivation fragment
  | (fst :: rest) -> 
        match fragment with
        | [] -> None
        | (hd :: tl) -> match fst with
                        | N a -> 
                            let new_acceptor = and_matcher orig_rules rest acceptor
                            in 
                            N_or_matcher orig_rules a (orig_rules a) (and_matcher orig_rules rest acceptor) derivation fragment
                        | T b -> match hd with
                                 | b -> and_matcher orig_rules rest acceptor derivation tl
                                 | _ -> None
*)

(* the recursive function that deals with the "and" cases *)
(* use this function to completely match the suffix with the symbols in our rules *)
let rec and_matcher orig_rules pick_rules acceptor derivation fragment =
  match pick_rules with
  (* no more alternative to examine, 
     plug derivation and fragment into the acceptor, 
     return what acceptor returns                    *)
  | [] -> acceptor derivation fragment
  (* If the first symbol of the rule is a nonterminal, parse this symbol *)
  | ((N fst) :: rest) ->
      let new_acceptor = and_matcher orig_rules rest acceptor
      in (* In this situation, we need to update the acceptor on the fly *)
      (* Call or_matcher to find possible derivations for this, applying the new acceptor *)
      or_matcher orig_rules fst (orig_rules fst) new_acceptor derivation fragment
  (* If the first symbol is a terminal, match the head of the current fragment with this symbol *)
  | ((T fst) :: rest) ->
      match fragment with 
      | [] -> None (* If there is no token in fragment, return None *)
      (* If matches, we keep going by recursive calls *)
      | (hd :: tl) -> if (hd = fst) then (and_matcher orig_rules rest acceptor derivation tl)
                      else None (* If fails, returns None *)

(* the function deals with the "disjunction" produced by symbols with several rules *)
and or_matcher orig_rules start pick_rules acceptor derivation fragment =
  match pick_rules with
  (* return None when there is no matched alternative *)
  | [] -> None
  | (fst :: rest) -> 
        let check_suffix = and_matcher orig_rules fst acceptor (append_dev derivation start fst) fragment
        in (* call the and_matcher to recursively check the suffix *)
        match check_suffix with
        (* If and_matcher returns None,
           pick the next rule in the list of rule alternatives and call or_matcher again
         *)
        | None -> or_matcher orig_rules start rest acceptor derivation fragment
        | other -> other (* Otherwise, we accept this step of derivation and move on. *)

(* Main function *)
let parse_prefix grammar acceptor fragment = 
	match grammar with
	| (start, orig_rules) -> or_matcher orig_rules start (orig_rules start) acceptor [] fragment
(* orig_rules is a function, which returns a list of possible rules for a prefix. *)

