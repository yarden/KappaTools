(*
  * views_domain.mli
  * openkappa
  * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
  *
  * Creation: 2016, the 30th of January
  * Last modification: Time-stamp: <Aug 30 2016>
  *
  * A monolitich domain to deal with all concepts in reachability analysis
  * This module is temporary and will be split according to different concepts
  * thanks to the functor Product
  *
  * Copyright 2010,2011,2012,2013,2014,2015,2016 Institut National de Recherche
  * en Informatique et en Automatique.
  * All rights reserved.  This file is distributed
  * under the terms of the GNU Library General Public License *)

(** Abstract domain to over-approximate the set of reachable views *)
let local_trace = false

module Domain =
struct

  (* the type of the struct that contains all static information as in the
     previous version of the analysis *)

  (* domain specific info: *)
  (* collect the set of tuples (A,x,y,B,z,t) such that there exists a rule
     with two agents of type A and B and two bonds between A.x and B.z, and A.y
     and B.t *)
  (* for each tuple, collect a map -> (A,x,y,B,z,t) -> (Ag_id,Ag_id) list
     RuleIdMap to explain which rules can create a bond of type A.x.z.B
     (and at which position (its internal state ~u~p, ...).*)
  (* a map -> (A,x,y,B,z,t) -> (Ag_id,Ag_id) list RuleIdMap to explain
     which rules can create a bond of type A.y.t.B (and at which position *)
  (* and a map (A,x,y,B,z,t) -> (Ag_id,Ag_id) list RuleIdMap to explain
     which rules can contain parallel bonds in their lhs *)

  type static_information =
    {
      global_static_information : Analyzer_headers.global_static_information;
      local_static_information  : Parallel_bonds_static.local_static_information
    }

  (*--------------------------------------------------------------*)
  (* one map: for each tuple: Yes, No, Maybe, *)
  (* Yes: to say that when the sites x and y are bound with sites of
     the good type, then they are bound to the same B*)
  (* No: to say that when the sites x and y are bound with sites of the good
     type, then they are never bound to the same B*)
  (* Maybe: both case may happen*)

  type local_dynamic_information =
    {
      dummy: unit;
      store_value:
        bool Usual_domains.flat_lattice
          Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.t
    }

  type dynamic_information =
    {
      local  : local_dynamic_information ;
      global : Analyzer_headers.global_dynamic_information;
    }

  (*-------------------------------------------------------------*)
  (** global static information.
      explain how to extract the handler for kappa expressions from a value
      of type static_information. Kappa handler is static and thus it should
      never updated. *)

  let get_global_static_information static = static.global_static_information

  let lift f x = f (get_global_static_information x)

  let get_parameter static = lift Analyzer_headers.get_parameter static

  let get_kappa_handler static = lift Analyzer_headers.get_kappa_handler static

  let get_compil static = lift Analyzer_headers.get_cc_code static

  let get_local_static_information static = static.local_static_information

  let set_local_static_information local static =
    {
      static with
      local_static_information = local
    }

  let get_rule parameter error static r_id =
    let compil = get_compil static in
    let error, rule  =
      Ckappa_sig.Rule_nearly_Inf_Int_storage_Imperatif.get
        parameter
        error
        r_id
        compil.Cckappa_sig.rules
    in
    error, rule

  let get_action_binding static =
    (get_local_static_information
       static).Parallel_bonds_static.store_action_binding

  let set_action_binding bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_action_binding = bonds
      }
      static

  let get_views_rhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_views_rhs

  let set_views_rhs bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_views_rhs = bonds
      }
      static

  (*parallel bonds*)

  let get_tuples_of_interest static =
    (get_local_static_information
       static).Parallel_bonds_static.store_tuples_of_interest

  let set_tuples_of_interest bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_tuples_of_interest = bonds
      }
      static

  let get_rule_double_bonds_rhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_rule_double_bonds_rhs

  let set_rule_double_bonds_rhs bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_rule_double_bonds_rhs = bonds
      }
      static

  let get_fst_site_create_parallel_bonds_rhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_fst_site_create_parallel_bonds_rhs

  let set_fst_site_create_parallel_bonds_rhs l static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_fst_site_create_parallel_bonds_rhs = l
      }
      static

  let get_snd_site_create_parallel_bonds_rhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_snd_site_create_parallel_bonds_rhs

  let set_snd_site_create_parallel_bonds_rhs l static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_snd_site_create_parallel_bonds_rhs = l
      }
      static

  let get_rule_double_bonds_lhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_rule_double_bonds_lhs

  let set_rule_double_bonds_lhs bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_rule_double_bonds_lhs = bonds
      }
      static

  (*---------------------------------------------------------------*)
  (*dynamic information*)

  let get_global_dynamic_information dynamic = dynamic.global

  let get_local_dynamic_information dynamic = dynamic.local

  let set_local_dynamic_information local dynamic =
    {
      dynamic with local = local
    }

  let set_global_dynamic_information global dynamic =
    {
      dynamic with global = global
    }

  (*current value of parallel bonds*)
  let get_value dynamic =
    (get_local_dynamic_information dynamic).store_value

  let set_value value dynamic =
    set_local_dynamic_information
      {
        (get_local_dynamic_information dynamic) with
        store_value = value
      } dynamic

  (*--------------------------------------------------------------*)

  type 'a zeroary =
    static_information
    -> dynamic_information
    -> Exception.method_handler
    -> Exception.method_handler * dynamic_information * 'a

  type ('a, 'b) unary =
    static_information
    -> dynamic_information
    -> Exception.method_handler
    -> 'a
    -> Exception.method_handler * dynamic_information * 'b

  type ('a, 'b, 'c) binary =
    static_information
    -> dynamic_information
    -> Exception.method_handler
    -> 'a
    -> 'b
    -> Exception.method_handler * dynamic_information * 'c

  (****************************************************************)
  (*rule*)
  (*****************************************************************)

  let scan_rule static _dynamic error rule_id rule =
    let parameter = get_parameter static in
    (*------------------------------------------------------*)
    (*views on the right hand side*)
    let store_views_rhs = get_views_rhs static in
    let error, store_views_rhs =
      Parallel_bonds_static.collect_views_rhs
        parameter error rule_id rule store_views_rhs
    in
    let static = set_views_rhs store_views_rhs static in
    (*------------------------------------------------------*)
    (*action created a binding site*)
    let store_action_binding = get_action_binding static in
    let error, store_action_binding =
      Parallel_bonds_static.collect_action_binding
        parameter error rule_id rule store_action_binding
    in
    let static = set_action_binding store_action_binding static in
    (*------------------------------------------------------*)
    (*a set of rules that has a potential double binding or potential non parallel binding on the lhs*)
    let store_result = get_rule_double_bonds_lhs static in
    let error, store_result =
      Parallel_bonds_static.collect_rule_double_bonds_lhs
        parameter error rule_id rule store_result
    in
    let static = set_rule_double_bonds_lhs store_result static in
    (*------------------------------------------------------*)
    (*a set of rules that has a potential double bindings on the rhs*)
    let store_result = get_rule_double_bonds_rhs static in
    let error, store_result =
      Parallel_bonds_static.collect_rule_double_bonds_rhs
        parameter error rule_id rule store_result
    in
    let static = set_rule_double_bonds_rhs store_result static in
    error, static

  (****************************************************************)

  let scan_rules static dynamic error =
    let parameter = get_parameter static in
    let compil = get_compil static in
    let error, static =
      Ckappa_sig.Rule_nearly_Inf_Int_storage_Imperatif.fold
        parameter
        error
        (fun _ error rule_id rule static ->
           scan_rule
             static dynamic error rule_id rule.Cckappa_sig.e_rule_c_rule
        ) compil.Cckappa_sig.rules static
    in
    (*------------------------------------------------------*)
    (*A(x!1, y), B(x!1, y): first site is an action binding*)
    (*------------------------------------------------------*)
    let lift_map error s =
      Ckappa_sig.Rule_map_and_set.Map.fold
        (fun _ big_store (error, set) ->
           Parallel_bonds_static.project_away_ag_id_and_convert_into_set
             parameter error big_store set)
        s
        (error, Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.empty)
    in
    let error, store_result1 =
      lift_map error (get_rule_double_bonds_lhs static) in
    let error, store_result2 =
      lift_map error (get_rule_double_bonds_rhs static) in
    let error, store_result =
      Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.union
        parameter error store_result1 store_result2
    in
    let static =
      set_tuples_of_interest store_result static
    in
    let tuple_of_interest = store_result in
    let store_action_binding = get_action_binding static in
    let error, store_result =
      Parallel_bonds_static.collect_fst_site_create_parallel_bonds_rhs
        parameter error store_action_binding tuple_of_interest
    in
    let static = set_fst_site_create_parallel_bonds_rhs store_result static in
    (*------------------------------------------------------*)
    (*A(x, y!1), B(x, y!1): second site is an action binding *)
    let error, store_result =
      Parallel_bonds_static.collect_snd_site_create_parallel_bonds_rhs
        parameter error store_action_binding tuple_of_interest
    in
    let static = set_snd_site_create_parallel_bonds_rhs store_result static in
    error, static, dynamic

  (***************************************************************)

  let initialize static dynamic error =
    let init_global_static_information =
      {
        global_static_information = static;
        local_static_information = Parallel_bonds_static.init_local_static;
      }
    in
    let init_local_dynamic_information =
      {
        dummy = ();
        store_value =
          Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty
      }
    in
    let init_global_dynamic_information =
      {
        global = dynamic;
        local = init_local_dynamic_information ;
      }
    in
    let error, static, dynamic =
      scan_rules
        init_global_static_information
        init_global_dynamic_information error
    in
    error, static, dynamic

  (***************************************************************)
  (*Initial state*)
  (***************************************************************)

  (***************************************************************)
  (*a map of parallel bonds in the initial states, if the set
    if empty then return false, if it has parallel bonds return
    true.*)

  let compute_value_init static dynamic error init_state =
    let parameter = get_parameter static in
    let tuples_of_interest =
      get_tuples_of_interest static
    in
    let kappa_handler = get_kappa_handler static in
    (*value of parallel and non parallel bonds*)
    let store_result = get_value dynamic in
    let error, store_result =
      Parallel_bonds_init.collect_parallel_or_not_bonds_init
        parameter kappa_handler error
        tuples_of_interest init_state store_result
    in
    let dynamic = set_value store_result dynamic in
    error, dynamic

  (*************************************************************)

  let add_initial_state static dynamic error species =
    let event_list = [] in
    (*parallel bonds in the initial states*)
    let error, dynamic =
      compute_value_init static dynamic error species
    in
    error, dynamic, event_list

  (*************************************************************)
  (* if a parallel bound occur in a lhs, check that this is possible *)

  let is_enabled static dynamic error (rule_id:Ckappa_sig.c_rule_id) precondition =
    let parameter = get_parameter static in
    (*-----------------------------------------------------------*)
    (*a set of rules has parallel bonds on the lhs*)
    let store_rule_has_parallel_bonds_lhs = get_rule_double_bonds_lhs static in
    let error, parallel_map =
      match Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs
              parameter error rule_id store_rule_has_parallel_bonds_lhs
      with
      | error, None ->
        error,
        Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty
      | error, Some s -> error, s
    in
    let list =
      Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.bindings parallel_map
    in
    (*-----------------------------------------------------------*)
    let store_value = get_value dynamic in
    let error, bool =
      begin
        let rec scan list error =
          match
            list
          with
          | [] -> error, true
          | (tuple,parallel_or_not)::tail ->
            let pair = Parallel_bonds_type.project2 tuple in
            let error, value =
              match
                Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.find_option_without_logs
                  parameter error
                  pair
                  store_value
              with
              | error, None -> error, Usual_domains.Undefined
              | error, Some v -> error, v
            in
            match value with
            | Usual_domains.Undefined | Usual_domains.Val false -> error, false
            | Usual_domains.Val b when b<> parallel_or_not
              -> error, false
            | Usual_domains.Val _
            |  Usual_domains.Any -> scan tail error
        in
        scan list error
      end
    in
    if bool
    then error, dynamic, Some precondition
    else
      error, dynamic, None

  (***************************************************************)
  (* when one bond is created, check in the precondition, whether the two
     other sites may be bound, check whether they must be bound to the same
     agents, whether they cannot be bound to the same agent, whether we cannot
     know, and deal with accordingly *)


  (***********************************************************)
  (* we know from the syntax that a created bond necessarily belongs to
     a pair of parallel bonds or a pair of non-parallel bonds *)
  let necessarily_double idx idy (x,y) map =
    Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.mem
      (idx,(x,y))
      map || Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.mem
      (idy,(y,x))
      map

  type pos = Fst | Snd
  let apply_gen pos parameter error static dynamic precondition rule_id rule =
    let store_site_create_parallel_bonds_rhs =
      match pos
      with
      | Fst -> get_fst_site_create_parallel_bonds_rhs static
      | Snd -> get_snd_site_create_parallel_bonds_rhs static
    in
    let error, store_pair_bind_map =
      match
        Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs
          parameter error
          rule_id
          store_site_create_parallel_bonds_rhs
      with
      | error, None -> error,
                       Parallel_bonds_type.PairAgentsSiteState_map_and_set.Map.empty
      | error, Some m -> error, m
    in
    let store_rule_double_bonds_rhs = get_rule_double_bonds_rhs static in
    let error, rule_double_bonds_rhs_map =
      match
        Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs
          parameter error rule_id store_rule_double_bonds_rhs
      with
      | error, None ->
        error, Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty
      | error, Some map -> error, map
    in
    (*-----------------------------------------------------------*)
    Parallel_bonds_type.PairAgentsSiteState_map_and_set.Map.fold
      (fun (_, _) parallel_list (error, dynamic, precondition, store_result) ->
         let error, dynamic, precondition, store_result =
           List.fold_left
             (fun
               (error, dynamic, precondition, store_result) (z, t) ->
               let (agent_id1, agent_type1, site_type1, site_type2, state1, state2) = z in
               let (agent_id1', agent_type1', site_type1', site_type2', state1', state2') = t in
               let z' = Parallel_bonds_type.project z in
               let t' = Parallel_bonds_type.project t in
               let other_site, other_site' =
                 match pos with
                 | Fst -> site_type2, site_type2'
                 | Snd -> site_type1, site_type1'
               in
               if
                 necessarily_double
                   agent_id1 agent_id1' (z',t')
                   rule_double_bonds_rhs_map
               then
                 (error, dynamic, precondition, store_result)
               else
                 (*to be checked the agent_type, and site_type1*)
                 let error, old_value =
                   match
                     Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.find_option_without_logs
                       parameter error
                       (agent_id1,(z', t'))
                       store_result
                   with
                   | error, None ->
                     error, Usual_domains.Undefined
                   | error, Some value -> error, value
                 in
                 (*------------------------------------------------------*)
                 (*get a list of potential states of the second site*)
                 let error, dynamic, precondition, state_list =
                   Communication.get_state_of_site_in_postcondition
                     get_global_static_information
                     get_global_dynamic_information
                     set_global_dynamic_information
                     error static  dynamic
                     (rule_id,rule) agent_id1 (*A*) other_site
                     precondition
                 in
                 let error, dynamic, precondition, state_list' =
                   Communication.get_state_of_site_in_postcondition
                     get_global_static_information
                     get_global_dynamic_information
                     set_global_dynamic_information
                     error static dynamic
                     (rule_id,rule) agent_id1' (*B*) other_site'
                     precondition
                 in
                 let error, potential_list =
                   List.fold_left
                     (fun (error, current_list) pre_state ->
                        List.fold_left
                          (fun (error, current_list) pre_state' ->
                             let state1, state2, state1', state2' =
                               match pos with
                               | Fst ->  state1, pre_state, state1', pre_state'
                               | Snd ->  pre_state, state2, pre_state', state2'
                             in
                             let potential_list =
                               ((agent_id1, agent_type1, site_type1, site_type2, state1, state2),
                                (agent_id1', agent_type1', site_type1', site_type2', state1', state2'))
                               :: current_list
                             in
                             error, potential_list
                          ) (error, current_list) state_list'
                     ) (error, []) state_list
                 in
                 (*------------------------------------------------------*)
                 (*fold over a potential list and compare with parallel list*)
                 let error, value =
                   List.fold_left (fun (error, value) (x', y') ->
                       let site_other, pre_state_other, site_other', pre_state_other' =
                         match pos
                         with Fst ->
                           let (_, _, _, s_type2, _, pre_state2) = x' in
                           let (_, _, _, s_type2', _, pre_state2') = y' in
                           s_type2,pre_state2, s_type2', pre_state2'
                            | Snd ->
                              let (_,_,s_type1,_,pre_state1,_) = x' in
                              let (_,_,s_type1',_,pre_state1',_) = y' in
                              s_type1, pre_state1, s_type1', pre_state1'
                       in
                       (*check if the pre_state2 and pre_state2' of the other sites are
                                                  bound and if yes which the good state?  - Firstly check that if the
                                                  parallel bonds depend on the state of the
                                                  second site, it will give a different value: whether Undefined or
                                                  Any, (question 1 and 2)*)
                       begin
                         (*question 1: if the pre_state2/pre_state2' of A or B is free -> undefined*)
                         if Ckappa_sig.int_of_state_index pre_state_other = 0
                         then
                           (*answer of question 1: the second site is free*)
                           let new_value = Usual_domains.lub value Usual_domains.Undefined in
                           error, new_value
                         else
                           (* the pre_state2 is bound or pre_state2' is bound. Question
                              2: both sites are bound with the good sites, then return Any,
                              if not return false*)
                           begin
                             if site_other = site_other' && pre_state_other = pre_state_other' &&
                                not (Ckappa_sig.int_of_state_index pre_state_other' = 0)
                             then
                               (*both question1 and 2 are yes: return any*)
                               let new_value = Usual_domains.lub value Usual_domains.Any in
                               error, new_value
                             else
                               (*the question1 is true but the question 2 is false -> false*)
                               let new_value = Usual_domains.lub value (Usual_domains.Val false) in
                               error, new_value
                           end
                       end
                     ) (error, old_value) potential_list
                 in
                 (*------------------------------------------------------*)
                 (*call the symmetric add *)
                 let error, store_result =
                   Parallel_bonds_type.add_symmetric_tuple_pair
                     (fun parameter error t map ->
                        Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.add_or_overwrite
                          parameter error
                          t
                          value
                          map)
                     parameter
                     error
                     (z, t)
                     store_result
                 in
                 error, dynamic, precondition, store_result
             ) (error, dynamic, precondition, store_result) parallel_list
         in
         error, dynamic, precondition, store_result
      ) store_pair_bind_map
      (error, dynamic, precondition,
       Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty)

  let apply_rule static dynamic error rule_id precondition =
    let event_list = [] in
    let parameter = get_parameter static in
    let kappa_handler = get_kappa_handler static in
    (*-----------------------------------------------------------*)
    let error, rule = get_rule parameter error static rule_id in
    match
      rule
    with
    | None ->
      let error, () =
        Exception.warn parameter error __POS__ Exit ()
      in
      error, dynamic, (precondition, event_list)
    | Some rule ->
      let parameter =
        Remanent_parameters.update_prefix parameter "                "
      in
      let dump_title () =
        if local_trace || Remanent_parameters.get_dump_reachability_analysis_diff parameter
        then
          let () =
            Loggers.fprintf
              (Remanent_parameters.get_logger parameter)
              "%sUpdate information about potential double bindings"
              (Remanent_parameters.get_prefix parameter)
          in
          Loggers.print_newline (Remanent_parameters.get_logger parameter)
        else
          ()
      in
      (*------------------------------------------------------------------*)
      (*the rule creates a bond matching with
        the first bond in a potential double bindings*)
      (*-----------------------------------------------------------*)
      let error, dynamic, precondition, store_value1 =
        apply_gen Fst parameter error static dynamic precondition rule_id rule
      in
      (*------------------------------------------------------------------*)
      (*the rule creates a bond matching with
        the second bond in a potential double bindings*)
      (*-----------------------------------------------------------*)
      let error, dynamic, precondition, store_value2 =
        apply_gen Snd parameter error static dynamic precondition rule_id rule
      in
  (*-----------------------------------------------------------*)
  (*combine two value above*)
  let bool =
    if Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.is_empty store_value1
    && Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.is_empty store_value2
    then
      false
    else
      let () = dump_title () in
      true
  in
  let error, store_value =
    Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.fold2
      parameter error
      (fun parameter error x value store_result ->
         let error, store_result =
           Parallel_bonds_type.add_value_from_refined_tuple
             parameter error kappa_handler x value store_result
         in
         error, store_result
      )
      (fun parameter error x value store_result ->
         let error, store_result =
           Parallel_bonds_type.add_value_from_refined_tuple
             parameter error kappa_handler
             x value store_result
         in
         error, store_result
      )
      (fun parameter error x value1 value2 store_result ->
         let new_value = Usual_domains.lub value1 value2 in
         let error, store_result =
           Parallel_bonds_type.add_value_from_refined_tuple
             parameter error kappa_handler
             x new_value store_result
         in
         error, store_result
      )
      store_value1
      store_value2
      Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty
  in
  (*--------------------------------------------------------------*)
  (*if it belongs to non parallel bonds then false*)
  let store_parallel_map = get_rule_double_bonds_rhs static in
  let error, double_rhs_list =
    match
      Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs parameter
        error rule_id store_parallel_map
    with
    | error, None ->
      error,
      Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty
    | error, Some m -> error, m
  in
  let error, store_non_parallel =
    Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.fold
      (fun (_,y) b (error, store_result)  ->
         if b then error, store_result
         else
           let error, store_result =
             Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.add_or_overwrite
               parameter error
               y (Usual_domains.Val false)
               store_result
           in
           error, store_result
      )
      double_rhs_list
      (error, Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty)
  in
  (*--------------------------------------------------------------*)
  (*fold with store_value above*)
  let error, map_value = error, store_value in
  let () =
    if not bool &&
       Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.is_empty
         store_non_parallel
    then
      ()
    else
      dump_title ()
  in
  let store_result = get_value dynamic in
  let error, store_result =
    Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.fold2
      parameter error
      (fun parameter error x value store_result ->
         Parallel_bonds_type.add_value parameter error kappa_handler x value store_result
      )
      (fun parameter error x value store_result ->
         Parallel_bonds_type.add_value parameter error kappa_handler x value store_result
      )
      (fun parameter error x value1 value2 store_result ->
         let new_value = Usual_domains.lub value1 value2 in
         Parallel_bonds_type.add_value parameter error kappa_handler x new_value store_result
      )
      map_value
      store_non_parallel
      store_result
  in
  let dynamic = set_value store_result dynamic in
  (*--------------------------------------------------------------*)
  (*if it belongs to parallel bonds then true*)
  let error, store_parallel =
    Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.fold
      (fun (x, y) b (error, store_result) ->
         if b then
           let pair = Parallel_bonds_type.project2 (x, y) in
           let error, store_result =
             Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.add_or_overwrite
               parameter error
               pair
               (Usual_domains.Val true)
               store_result
           in
           error, store_result
         else error, store_result
      )
      double_rhs_list
      (error, Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty)
  in
  (*--------------------------------------------------------------*)
  (*fold over the store_value and parallel bond value *)
  let () =
    if not bool &&
       Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.is_empty
         store_parallel
    then
      ()
    else
      dump_title ()
  in
  let store_result = get_value dynamic in
  let error, store_result =
    Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.fold2
      parameter error
      (fun parameter error x value store_result ->
         Parallel_bonds_type.add_value parameter error
           kappa_handler x value store_result
      )
      (fun parameter error x value store_result ->
         Parallel_bonds_type.add_value parameter error
           kappa_handler x value store_result
      )
      (fun parameter error x value1 value2 store_result ->
         let new_value = Usual_domains.lub value1 value2 in
         Parallel_bonds_type.add_value parameter error
           kappa_handler x new_value store_result
      )
      map_value
      store_parallel
      store_result
  in
  let dynamic = set_value store_result dynamic in
  error, dynamic, (precondition, event_list)

  (* events enable communication between domains. At this moment, the
     global domain does not collect information *)

  let apply_event_list _static dynamic error _event_list =
    let event_list = [] in
    error, dynamic, event_list

  (****************************************************************)

  let stabilize _static dynamic error = error, dynamic, ()
  let print static dynamic (error:Exception.method_handler) loggers =
    let kappa_handler = get_kappa_handler static in
    let parameter = get_parameter static in
    let log = loggers in
    (*-------------------------------------------------------*)
    let error =
      if Remanent_parameters.get_dump_reachability_analysis_result
          parameter
      then
        let () =
          Loggers.fprintf log
            "------------------------------------------------------------\n";
          Loggers.fprintf log "* Properties of pairs of bonds\n";
          Loggers.fprintf log
            "------------------------------------------------------------\n"
        in
        let store_value = get_value dynamic in
        let error =
          Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.fold
            (fun tuple value error ->
               Parallel_bonds_type.print_parallel_constraint
                 ~verbose:true
                 ~sparse:true
                 ~final_resul:true
                 ~dump_any:true parameter error kappa_handler tuple value
            ) store_value error
        in error
      else
        error
    in
    error, dynamic, ()

  (****************************************************************)

  let export _static dynamic error kasa_state =
    error, dynamic, kasa_state

  let lkappa_mixture_is_reachable _static dynamic error _lkappa =
    error, dynamic, Usual_domains.Maybe (* to do *)

  let cc_mixture_is_reachable _static dynamic error _ccmixture =
    error, dynamic, Usual_domains.Maybe (* to do *)

end
