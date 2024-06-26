(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open PulseBasicInterface
open PulseDomainInterface
open PulseOperationResult.Import
open PulseModelsImport

type astate = AbductiveDomain.t

type 'a result = 'a AccessResult.t

type aval = AbstractValue.t * ValueHistory.t

(* we work on a disjunction of executions, but only in ContinueProgram mode *)
type 'a model_monad = model_data -> astate -> ('a * astate) result list

module Syntax = struct
  let ret (a : 'a) : 'a model_monad = fun _data astate -> [Ok (a, astate)]

  let unreachable : 'a model_monad = fun _ _ -> []

  let bind (x : 'a model_monad) (f : 'a -> 'b model_monad) : 'b model_monad =
   fun data astate ->
    List.concat_map (x data astate) ~f:(function
      | Ok (a, astate) ->
          f a data astate
      | Recoverable ((a, astate), err) ->
          f a data astate |> List.map ~f:(PulseResult.append_errors err)
      | FatalError _ as err ->
          [err] )


  let ( let* ) a f = bind a f

  let list_fold (list : 'a list) ~(init : 'accum) ~(f : 'accum -> 'a -> 'accum model_monad) :
      'accum model_monad =
    List.fold list ~init:(ret init) ~f:(fun monad a ->
        let* acc = monad in
        f acc a )


  let list_iter (list : 'a list) ~(f : 'a -> unit model_monad) : unit model_monad =
    list_fold list ~init:() ~f:(fun () a -> f a)


  let list_filter_map (list : 'a list) ~(f : 'a -> 'b option model_monad) : 'b list model_monad =
    let* rev_res =
      list_fold list ~init:[] ~f:(fun acc a ->
          let* opt = f a in
          match opt with None -> ret acc | Some b -> b :: acc |> ret )
    in
    List.rev rev_res |> ret


  let get_data : model_data model_monad = fun data astate -> ret data data astate

  let ok x = Ok x

  let sat x = Sat x

  let ( >> ) f g x = f x |> g

  let start_model (monad : unit model_monad) : model =
   fun data astate ->
    List.map (monad data astate) ~f:(PulseResult.map ~f:(fun ((), astate) -> ContinueProgram astate))


  let disjuncts (list : 'a model_monad list) : 'a model_monad =
   fun data astate -> List.concat_map list ~f:(fun m -> m data astate)


  let exec_partial_command (f : astate -> astate PulseOperationResult.t) : unit model_monad =
   fun _data astate ->
    match f astate with
    | Unsat ->
        []
    | Sat res ->
        [PulseResult.map res ~f:(fun astate -> ((), astate))]


  let exec_command (f : astate -> astate) : unit model_monad =
   fun _data astate -> [ok ((), f astate)]


  let exec_partial_operation (f : astate -> (astate * 'a) PulseOperationResult.t) : 'a model_monad =
   fun _data astate ->
    match f astate with
    | Unsat ->
        []
    | Sat res ->
        [PulseResult.map res ~f:(fun (astate, a) -> (a, astate))]


  let exec_operation (f : astate -> 'a) : 'a model_monad =
   fun data astate -> ret (f astate) data astate


  let assign_ret aval : unit model_monad =
    let* {ret= ret_id, _} = get_data in
    PulseOperations.write_id ret_id aval |> exec_command


  let eval_deref_access access_mode aval access : aval model_monad =
    let* {path; location} = get_data in
    PulseOperations.eval_deref_access path access_mode location aval access
    >> sat |> exec_partial_operation


  let add_dynamic_type typ (addr, _) : unit model_monad =
    PulseOperations.add_dynamic_type typ addr |> exec_command


  let get_dynamic_type ~ask_specialization (addr, _) : Typ.t option model_monad =
   fun data astate ->
    let res = AbductiveDomain.AddressAttributes.get_dynamic_type addr astate in
    let astate =
      if ask_specialization && Option.is_none res then
        AbductiveDomain.add_need_dynamic_type_specialization addr astate
      else astate
    in
    ret res data astate


  let and_eq_int (size_addr, _) i : unit model_monad =
    PulseArithmetic.and_eq_int size_addr i |> exec_partial_command


  let mk_fresh ~model_desc : aval model_monad =
    let* {path; location} = get_data in
    let addr = AbstractValue.mk_fresh () in
    let hist = Hist.single_call path location model_desc in
    ret (addr, hist)


  let write_deref_field ~ref ~obj field : unit model_monad =
    let* {path; location} = get_data in
    PulseOperations.write_deref_field path location ~ref ~obj field >> sat |> exec_partial_command


  let deep_copy ?depth_max source : aval model_monad =
    let* {path; location} = get_data in
    PulseOperations.deep_copy ?depth_max path location source >> sat |> exec_partial_operation


  let aval_operand (addr, _) = PulseArithmetic.AbstractValueOperand addr

  let prune_binop ~negated binop operand1 operand2 =
    PulseArithmetic.prune_binop ~negated binop operand1 operand2 |> exec_partial_command


  let dynamic_dispatch ~(cases : (Typ.name * 'a model_monad) list) aval : 'a model_monad =
    let* opt_typ = get_dynamic_type ~ask_specialization:true aval in
    match opt_typ with
    | Some {Typ.desc= Tstruct type_name} -> (
      match List.find cases ~f:(fun case -> fst case |> Typ.Name.equal type_name) with
      | Some (_, case_fun) ->
          case_fun
      | None ->
          Logging.d_printfln "[ocaml model] dynamic_dispatch: no case for type %a" Typ.Name.pp
            type_name ;
          disjuncts [] )
    | _ ->
        disjuncts []
end
