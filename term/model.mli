(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

(** Compiled representation of a full Kappa model *)

type t

val init :
  Pattern.Env.t -> unit NamedDecls.t ->
  Alg_expr.t Locality.annot NamedDecls.t ->
  (Operator.DepSet.t * Operator.DepSet.t *
     Operator.DepSet.t array * Operator.DepSet.t array) ->
  ((string Locality.annot option * LKappa.rule Locality.annot) array *
     Primitives.elementary_rule array *
       Pattern.Set.t) ->
  Alg_expr.t Locality.annot array -> Primitives.perturbation array -> t
(** [init sigs tokens algs dependencies (ast_rules,rules) obs perts]
 *)

val nb_tokens : t -> int
val nb_algs : t -> int
val nb_rules : t -> int
val nb_syntactic_rules : t -> int
val nb_perturbations : t -> int
val connected_components_of_unary_rules : t -> Pattern.Set.t

val domain : t -> Pattern.Env.t
val new_domain : Pattern.Env.t -> t -> t
val signatures : t -> Signature.s
val tokens_finder : t -> int Mods.StringMap.t
val algs_finder : t -> int Mods.StringMap.t

val get_alg : t -> int -> Alg_expr.t
val get_algs : t -> (string * Alg_expr.t Locality.annot) array
val get_perturbation : t -> int -> Primitives.perturbation
val get_rule : t -> int -> Primitives.elementary_rule
val get_ast_rule: t -> int -> LKappa.rule
val get_ast_rule_rate_pos: unary:bool -> t -> int -> Locality.t
val map_observables : (Alg_expr.t -> 'a) -> t -> 'a array
val fold_rules :
  (int -> 'a -> Primitives.elementary_rule -> 'a) -> 'a -> t -> 'a
val fold_perturbations :
  (int -> 'a -> Primitives.perturbation -> 'a) -> 'a -> t -> 'a

val get_alg_reverse_dependencies : t -> int -> Operator.DepSet.t
val get_token_reverse_dependencies : t -> int -> Operator.DepSet.t
val get_always_outdated : t -> Operator.DepSet.t
val all_dependencies :
  t -> (Operator.DepSet.t * Operator.DepSet.t *
        Operator.DepSet.t array * Operator.DepSet.t array)

val num_of_agent : string Locality.annot -> t -> int
val num_of_alg : string Locality.annot -> t -> int
val num_of_token : string Locality.annot -> t -> int
val nums_of_rule : string -> t -> int list

val print_ast_rule : ?env:t -> Format.formatter -> int -> unit
val print_rule : ?env:t -> Format.formatter -> int -> unit
val print_agent : ?env:t -> Format.formatter -> int -> unit
val print_alg : ?env:t -> Format.formatter -> int -> unit
val print_token : ?env:t -> Format.formatter -> int -> unit

val print :
  (t -> Format.formatter -> Alg_expr.t -> unit) ->
  (t -> Format.formatter -> Primitives.elementary_rule -> unit) ->
  (t -> Format.formatter -> Primitives.perturbation -> unit) ->
  Format.formatter -> t -> unit

val to_yojson : t -> Yojson.Basic.json
val of_yojson : Yojson.Basic.json -> t

val check_if_counter_is_filled_enough : t -> unit
val propagate_constant :
  ?max_time:float -> ?max_events:int -> int list -> t -> t
(** [propagate_constant updated_vars env] *)
