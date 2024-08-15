(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open PulseBasicInterface
module AbductiveDomain = PulseAbductiveDomain
module AccessResult = PulseAccessResult

exception Foo of string

let map_path_condition_common ~f astate =
  let open SatUnsat.Import in
  let* phi, new_eqs = f astate.AbductiveDomain.path_condition in
  (* let new_eqs = RevList.map new_eqs ~f:(fun x -> Formula.pp_new_eq Format.std_formatter x; x)  in *)
  let astate = AbductiveDomain.set_path_condition phi astate in
  let+ result =
    AbductiveDomain.incorporate_new_eqs new_eqs astate >>| AccessResult.of_abductive_result
  in
  (result, (new_eqs:Formula.new_eqs))


let map_path_condition ~f astate =
  let open SatUnsat.Import in
  map_path_condition_common ~f astate >>| fst


let map_path_condition_with_ret ~f astate ret =
  let open SatUnsat.Import in
  let+ result, new_eqs = map_path_condition_common ~f astate in
  PulseResult.map result ~f:(fun result ->
      (result, AbductiveDomain.incorporate_new_eqs_on_val new_eqs ret) )


let literal_zero = Formula.ConstOperand (Cint IntLit.zero)

let and_nonnegative v astate =
  map_path_condition astate ~f:(fun phi ->
      Formula.and_less_equal literal_zero (AbstractValueOperand v) phi )


let and_positive v astate =
  map_path_condition astate ~f:(fun phi ->
      Formula.and_less_than literal_zero (AbstractValueOperand v) phi )


let and_eq_const v c astate =
  map_path_condition astate ~f:(fun phi ->
      Formula.and_equal (AbstractValueOperand v) (ConstOperand c) phi )


let and_eq_int v i astate = and_eq_const v (Cint i) astate

type operand = Formula.operand =
  | AbstractValueOperand of AbstractValue.t
  | ConstOperand of Const.t
  | FunctionApplicationOperand of {f: PulseFormula.function_symbol; actuals: AbstractValue.t list}

let and_equal lhs rhs astate =
  map_path_condition astate ~f:(fun phi -> Formula.and_equal lhs rhs phi)


let and_not_equal lhs rhs astate =
  map_path_condition astate ~f:(fun phi -> Formula.and_not_equal lhs rhs phi)


let eval_binop ret binop lhs rhs astate =
  map_path_condition_with_ret astate ret ~f:(fun phi ->
      Formula.and_equal_binop ret binop lhs rhs phi )


let eval_binop_absval ret binop lhs rhs astate =
  eval_binop ret binop (AbstractValueOperand lhs) (AbstractValueOperand rhs) astate


let eval_unop ret unop v astate =
  map_path_condition_with_ret astate ret ~f:(fun phi ->
      Formula.and_equal_unop ret unop (AbstractValueOperand v) phi )


let prune_binop ~negated binop lhs rhs astate =
  map_path_condition astate ~f:(fun phi -> Formula.prune_binop ~negated binop lhs rhs phi)


let literal_zero = ConstOperand (Cint IntLit.zero)

let literal_one = ConstOperand (Cint IntLit.one)

let prune_eq_zero v astate =
  prune_binop ~negated:false Eq (AbstractValueOperand v) literal_zero astate


let prune_ne_zero v astate =
  prune_binop ~negated:false Ne (AbstractValueOperand v) literal_zero astate


let prune_positive v astate =
  prune_binop ~negated:false Gt (AbstractValueOperand v) literal_zero astate


let prune_gt_one v astate =
  prune_binop ~negated:false Gt (AbstractValueOperand v) literal_one astate


let prune_eq_one v astate =
  prune_binop ~negated:false Eq (AbstractValueOperand v) literal_one astate


let is_known_zero astate v = Formula.is_known_zero astate.AbductiveDomain.path_condition v

(* let instance_check argv (summary:AbductiveDomain.Summary.t)= 
    let staic_ty = AbductiveDomain.Summary.get_static_type argv in 
    match staic_ty with 
    | None -> 

let is_instanceof_var var (summary:AbductiveDomain.Summary.t) = 
  let path = AbductiveDomain.Summary.get_path_condition summary in 
  

  let iter_atom atom (vv, r) = 
    match atom with 
    | Atom.Equal (Linear a, _)->  if Var.equal (linear_var a) vv then (vv, false) else (vv, r)
    | Atom.NotEqual (Linear a, _)->  if Var.equal (linear_var a) vv then (vv, true) else (vv, r)
    | _ ->  (vv, r) in 
let checking_instanceof_var var (formula:t) static_type = 
  let is_instance v atoms = 
    Atom.Set.fold iter_atom atoms (v,false) in  *)

let check_instance tenv argv path summary=
try

(* Formula.pp Format.std_formatter path; *)
(* print_endline "yes";
AbstractValue.pp Format.std_formatter argv;  *)

  let (a,b,c) = Formula.checking_instanceof_var true argv path in 
  
  if (a) then match AbductiveDomain.Summary.get_static_type b summary with 
                            | None -> false (*should consider dynamic type?*)
                            | Some typ1 -> 
                                ( match AbductiveDomain.Summary.get_dynamic_type b summary with
                                        |Some dty -> 
                                            let dty = Formula.ty_name dty in 
                                            let possible_subtype = Tenv.find_limited_sub dty tenv in 
                                            (* print_endline "";
                                            print_endline "xxxxxxxxxxxxxxxxxxxxx";
                                            print_endline ""; *)
                                            if (List.is_empty possible_subtype) && PatternMatch.is_subtype tenv dty typ1 && PatternMatch.is_subtype tenv typ1 dty then true else false 
                                        |None ->
                                        let typ2 = match c with 
                                            | None -> raise (Foo "impossible")
                                            | Some b -> Formula.ty_name b in 
              (* Typ.print_name typ2; *)
                                            let res = PatternMatch.is_subtype tenv typ1 typ2 in 
                                            res )
                                        (* else let (a2,b2,c2) = Formula.checking_instanceof_var false argv path in
                                                      if (a2) then match AbductiveDomain.Summary.get_static_type b2 summary with 
                                                        | None -> false (*should consider dynamic type?*)
                                                        | Some typ1 -> 
                                                                    let typ2 = match c2 with 
                                                                        | None -> raise (Foo "impossible")
                                                                        | Some t -> Formula.ty_name t in 
                                          (* Typ.print_name typ2; *)
                                                                        let res = (not(PatternMatch.is_subtype tenv typ1 typ2)) && (not(PatternMatch.is_subtype tenv typ2 typ1)) in 
                                                                        res                                              *)
    else false
  with Formula.Foo _ -> false


let stack_instance_check (summary:AbductiveDomain.Summary.summary) tenv= 
  
  let helper var = (match AbductiveDomain.Summary.get_static_type var summary with 
                        |None -> true 
                        |Some (sty:Typ.name
                        ) -> (match AbductiveDomain.Summary.get_dynamic_type var summary with 
                                      |None -> true 
                                      |Some dty -> 
                                        let dty = Formula.ty_name dty in 
                                        (* let possible_subtype = Tenv.find_limited_sub dty tenv in  *)
                                        (* print_endline "";
                                        print_endline "xxxxxxxxxxxxxxxxxxxxx";
                                        print_endline ""; *)
                                        (* if (List.is_empty possible_subtype) &&  *)
                                        if  PatternMatch.is_subtype tenv dty sty && PatternMatch.is_subtype tenv sty dty then true else false 
                        )
  )
  in

  let pre = AbductiveDomain.Summary.get_pre summary in 
  let abs_vars = PulseBaseDomain.reachable_addresses pre in 
  AbstractValue.Set.fold (fun x acc-> helper x && acc) abs_vars true


let is_manifest  ?(current_path = -1) ?(instra_hash: (Sil.instr, int) Caml.Hashtbl.t = Caml.Hashtbl.create 1000) ?(key : Sil.instr option = None) summary =
 
  let tenv = match (Tenv.load_global ()) with 
            | Some t -> t 
            | None -> Tenv.create ()
          in
  
  let statge1 = 
  let path = AbductiveDomain.Summary.get_path_condition summary in 
 
  (Formula.is_manifest (AbductiveDomain.Summary.get_path_condition summary) ~is_allocated:(fun v ->
      if check_instance tenv v path summary then true else
      AbductiveDomain.Summary.is_heap_allocated summary v
      || AbductiveDomain.Summary.get_must_be_valid v summary |> Option.is_some )) && stack_instance_check summary tenv 
      in 
  let statge2 = 
    
    
    if (Int.(=) current_path (-1)) then false else
    match key with
                | None -> false 
                | Some instr -> (match Caml.Hashtbl.find_opt instra_hash instr with 
                                | None -> if (Int.(=) current_path (1)) then (Caml.Hashtbl.add instra_hash instr 1; true) else (Caml.Hashtbl.add instra_hash instr 1; false)
                                | Some num -> if (Int.(=) (num + 1) current_path) then (Caml.Hashtbl.replace instra_hash instr (num+1); true )
                                              else (Caml.Hashtbl.replace instra_hash instr (num+1); false)
                                  )  in 
      statge1 || statge2 


let and_is_int v astate = map_path_condition astate ~f:(fun phi -> Formula.and_is_int v phi)

let and_equal_instanceof v1 v2 t astate =
  (* AbstractValue.pp Format.std_formatter v1;
  AbstractValue.pp Format.std_formatter v2;
  Typ.pp Pp.text Format.std_formatter t; *)
  (* print_endline "1"; *)

  map_path_condition astate ~f:(fun phi -> Formula.and_equal_instanceof v1 v2 t phi)
