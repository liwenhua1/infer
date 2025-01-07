(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format
open PulseBasicInterface
module AbductiveDomain = PulseAbductiveDomain
module Decompiler = PulseAbductiveDecompiler
module DecompilerExpr = PulseDecompilerExpr
module Diagnostic = PulseDiagnostic
module L = Logging

let add_call_to_access_to_invalid_address call_subst astate invalid_access =
  let expr_callee = invalid_access.Diagnostic.invalid_address in
  L.d_printfln "adding call to invalid address %a" DecompilerExpr.pp_with_abstract_value expr_callee ;
  let expr_caller =
    match
      let open IOption.Let_syntax in
      let* addr_callee = DecompilerExpr.abstract_value_of_expr expr_callee in
      AbstractValue.Map.find_opt addr_callee call_subst
    with
    | None ->
        (* the abstract value doesn't make sense in the caller: forget about it *)
        DecompilerExpr.reset_abstract_value expr_callee
    | Some (invalid_address, caller_history) ->
        let address_caller = Decompiler.find invalid_address astate in
        L.d_printfln "invalid_address= %a; address_caller= %a; caller_history= %a" AbstractValue.pp
          invalid_address DecompilerExpr.pp address_caller ValueHistory.pp caller_history ;
        address_caller
  in
  {invalid_access with Diagnostic.invalid_address= expr_caller}



type t =
  | AccessToInvalidAddress of Diagnostic.access_to_invalid_address
  | ErlangError of Diagnostic.ErlangError.t
  | ReadUninitializedValue of Diagnostic.read_uninitialized_value
  | JavaCastError of Diagnostic.cast_err
[@@deriving compare, equal, yojson_of]

let to_diagnostic = function
  | AccessToInvalidAddress access_to_invalid_address ->
      Diagnostic.AccessToInvalidAddress access_to_invalid_address
  | ErlangError erlang_error ->
      Diagnostic.ErlangError erlang_error
  | ReadUninitializedValue read_uninitialized_value ->
      Diagnostic.ReadUninitializedValue read_uninitialized_value
  | JavaCastError cast_e -> 
      Diagnostic.JavaCastError cast_e


let pp fmt latent_issue = Diagnostic.pp fmt (to_diagnostic latent_issue)

let add_call_to_calling_context call_and_loc = function
  | AccessToInvalidAddress access ->
      AccessToInvalidAddress {access with calling_context= call_and_loc :: access.calling_context}
  | ErlangError (Badarg {calling_context; location}) ->
      ErlangError (Badarg {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Badkey {calling_context; location}) ->
      ErlangError (Badkey {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Badmap {calling_context; location}) ->
      ErlangError (Badmap {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Badmatch {calling_context; location}) ->
      ErlangError (Badmatch {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Badrecord {calling_context; location}) ->
      ErlangError (Badrecord {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Badreturn {calling_context; location}) ->
      ErlangError (Badreturn {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Case_clause {calling_context; location}) ->
      ErlangError (Case_clause {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Function_clause {calling_context; location}) ->
      ErlangError (Function_clause {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (If_clause {calling_context; location}) ->
      ErlangError (If_clause {calling_context= call_and_loc :: calling_context; location})
  | ErlangError (Try_clause {calling_context; location}) ->
      ErlangError (Try_clause {calling_context= call_and_loc :: calling_context; location})
  | ReadUninitializedValue read ->
      ReadUninitializedValue {read with calling_context= call_and_loc :: read.calling_context}
  | JavaCastError cast_e -> 
    (* print_endline (Location.to_string (snd(call_and_loc))); *)
      JavaCastError {cast_e with calling_context= call_and_loc :: cast_e.calling_context}


let add_call call_and_loc call_subst astate latent_issue (_subs:(AbstractValue.t * ValueHistory.t) AbstractValue.Map.t) access=
  let latent_issue =
    match latent_issue with
    | AccessToInvalidAddress invalid_access ->
        let invalid_access =
          add_call_to_access_to_invalid_address call_subst astate invalid_access
        in
        AccessToInvalidAddress invalid_access

    | JavaCastError err ->
      (* Utils.print_bool access; *)
      JavaCastError {calling_context=err.calling_context; class_name =  err.class_name; target_class= err.target_class; allocation_trace = err.allocation_trace; location=err.location;num_instance = err.num_instance;apply_before = err.apply_before;private_or_report = access;abs_var = err.abs_var;is_equal=err.is_equal}
    | _ ->
        latent_issue
  in
  add_call_to_calling_context call_and_loc latent_issue

let reported_casting : (Location.t,bool) Caml.Hashtbl.t = Caml.Hashtbl.create 1000 
(* require a summary because we don't want to stop reporting because some non-abducible condition is
   not true as calling context cannot possibly influence such conditions *)
let should_report ?(current_path = -1) ?(instra_hash = Caml.Hashtbl.create 1000) ?(inst = None) ?(tag = true) (astate : AbductiveDomain.Summary.t) (diagnostic : Diagnostic.t)  =
  (*tag 是不是还没有报过*)
  let res =
  match diagnostic with
  | ConfigUsage _
  | ConstRefableParameter _
  | CSharpResourceLeak _
  | JavaResourceLeak _
  | HackUnawaitedAwaitable _
  | MemoryLeak _
  | ReadonlySharedPtrParameter _
  | RetainCycle _
  | StackVariableAddressEscape _
  | TaintFlow _
  | UnnecessaryCopy _ ->
      (* these issues are reported regardless of the calling context, not sure if that's the right
         decision yet *)
      `ReportNow
  | JavaCastError latent -> 
    
    (match latent.private_or_report with | true -> `DelayReport (JavaCastError latent) 
    |_ ->

    (match (Caml.Hashtbl.find_opt reported_casting latent.location) with 
    | None -> 
    (* `ReportNow *)
    (* print_endline (IR.Typ.Name.to_string latent.class_name); *)
      if latent.is_equal then ( (if tag then (Caml.Hashtbl.add reported_casting latent.location true)); `ReportNow) else
      if String.equal (IR.Typ.Name.to_string latent.class_name) "class java.lang.Object" then `DelayReport (JavaCastError latent) else
      if latent.apply_before then ( (if tag then (Caml.Hashtbl.add reported_casting latent.location true)); `ReportNow ) else `DelayReport (JavaCastError latent)
    (* if PulseArithmetic.is_manifest ~current_path:current_path ~instra_hash:instra_hash ~key:inst astate then `ReportNow
                                (* else if  not (Typ.Name.equal (latent.class_name) Typ.make_object) then `ReportNow.*)
                                else if (Int.(>) latent.num_instance 1) then `ReportNow
                                else `DelayReport (JavaCastError latent) *)
     | Some _ -> `DelayReport (JavaCastError latent)))

  | AccessToInvalidAddress latent -> 
      if PulseArithmetic.is_manifest ~current_path:current_path ~instra_hash:instra_hash ~key:inst astate then 
        (* let () = print_endline "ssssssssssssss" in *)
    
        `ReportNow
      else `DelayReport (AccessToInvalidAddress latent)
  | ErlangError latent ->
      if PulseArithmetic.is_manifest astate then `ReportNow else `DelayReport (ErlangError latent)
  | ReadUninitializedValue latent ->
      if PulseArithmetic.is_manifest ~current_path:current_path ~instra_hash:instra_hash ~key:inst astate then `ReportNow
      else `DelayReport (ReadUninitializedValue latent)

    in 
    (* let () = 
    match res with |`ReportNow -> print_endline "report now" |_ -> print_endline "delay" in *)
    res
