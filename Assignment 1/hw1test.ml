(* hw1test.ml *)

(* subset *)
let my_subset_test0 = subset [] []
let my_subset_test1 = subset [] [1;2;3]
let my_subset_test2 = subset [1;2;3] [3;1;2]
let my_subset_test3 = subset [1;2] [2;3;1]
let my_subset_test4 = not (subset [1;2;3] [1])
let my_subset_test5 = not (subset [2] [])

(* equal_sets *)
let my_equal_sets_test0 = equal_sets [] []
let my_equal_sets_test1 = equal_sets [1] [1]
let my_equal_sets_test2 = equal_sets [0;0;0] [0]
let my_equal_sets_test3 = not (equal_sets [1] [])
let my_equal_sets_test4 = not (equal_sets [1;2;3] [1])

(* set_union *)
let my_set_union_test0 = equal_sets (set_union [] []) []
let my_set_union_test1 = equal_sets (set_union [1] []) [1]
let my_set_union_test2 = equal_sets (set_union [1;2;4] [4;2;3]) [1;2;3;4]
let my_set_union_test3 = equal_sets (set_union [1;2;4] [4;2;1]) [1;2;4]

(* set_intersection *)
let my_set_intersection_test0 = 
  equal_sets (set_intersection [] []) []
let my_set_intersection_test1 =
  equal_sets (set_intersection [] [1]) []
let my_set_intersection_test2 = 
  equal_sets (set_intersection [1;1] [1;1;1;1]) [1]
let my_set_intersection_test3 =
  equal_sets (set_intersection [1;2;3] [2;4]) [2]

(* set_diff *)
let my_set_diff_test0 = equal_sets (set_diff [] []) []
let my_set_diff_test1 = equal_sets (set_diff [1;2;3;4;2] [4;1;4]) [2;3]

(* computed_fixed_point *)
let my_computed_fixed_point_test0 =
  ((computed_fixed_point (fun x y -> abs_float (x -. y) < 1.)
			 (fun x -> x /. 2.)
			 10.)
   = 1.25)
let my_computed_fixed_point_test1 =
  computed_fixed_point (=) sqrt 100. = 1.

(* computed_periodic_point *)
let my_computed_periodic_point_test0 =
  computed_periodic_point (=) (fun x -> -x) 2 1 = 1

(* while_away *)
let my_while_away_test0 = 
  equal_sets (while_away ((+) 3) ((>) 10) 0) [0; 3; 6; 9]
let my_while_away_test1 =
  equal_sets (while_away ((+) 2) ((>) 8) 1) [1; 3; 5; 7]

(* rle_decode *)
let my_rle_decode_test0 = 
  equal_sets (rle_decode [2,0; 1,6]) [0; 0; 6]
let my_rle_decode_test1 =
  equal_sets (rle_decode [3,"w"; 1,"x"; 0,"y"; 2,"z"]) ["w"; "w"; "w"; "x"; "z"; "z"]
let my_rle_decode_test2 = 
  equal_sets (rle_decode [0,5; 4,7; 2, 1]) [7; 7; 7; 7; 1; 1]

(* filter_blind_alleys *)
type nonterminals =
  | S | U | X | W

let rules =
   [S, [T "a"];
    S, [T "c"; N U];
    U, [T "d"];
    X, [N W; T "b"];
    W, [N X; T "a"]]

let grammar = S, rules

let my_filter_blind_alleys_test0 = filter_blind_alleys grammar = 
	(S, [S, [T "a"];
     S, [T "c"; N U];
     U, [T "d"]])





