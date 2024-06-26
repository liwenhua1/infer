(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open PulseDomainInterface

[@@@warning "-unused-value-declaration"]

val report : is_suppressed:bool -> latent:bool -> Procdesc.t -> Errlog.t -> Diagnostic.t -> unit

val report_summary_error :
     Tenv.t
  -> Procdesc.t
  -> Errlog.t
  -> ?current_path:int ->
   ?instra_hash:(Sil.instr, int) Caml.Hashtbl.t ->
   ?ins:Sil.instr option  -> 
   AccessResult.error * AbductiveDomain.Summary.t
  -> _ ExecutionDomain.base_t option
(** [None] means that the execution can continue but we could not compute the continuation state
    (because this only takes a [AccessResult.error], which doesn't have the ok state) *)

val report_result :
     Tenv.t
  -> Procdesc.t
  -> Errlog.t
  -> Location.t
  -> AbductiveDomain.t AccessResult.t
  -> ExecutionDomain.t list

val report_results :
     Tenv.t
  -> Procdesc.t
  -> Errlog.t
  -> Location.t
  -> ?current_disj:int ->
   ?instra_latent_hash:(Sil.instr, int) Caml.Hashtbl.t ->
   ?ins:Sil.instr option 
  -> AbductiveDomain.t AccessResult.t list
  -> ExecutionDomain.t list

val report_exec_results :
     Tenv.t
  -> Procdesc.t
  -> Errlog.t
  -> ?current_path:int ->
   ?instra_hash:(Sil.instr, int) Caml.Hashtbl.t ->
   ?ins:Sil.instr option -> Location.t
  -> ExecutionDomain.t AccessResult.t list
  -> ExecutionDomain.t list
