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
module Diagnostic = PulseDiagnostic

(** A subset of [PulseDiagnostic] that can be "latent", i.e. there is a potential issue in the code
    but we want to delay reporting until we see the conditions for the bug manifest themselves in
    some calling context. *)


type t =
  | AccessToInvalidAddress of Diagnostic.access_to_invalid_address
  | ErlangError of Diagnostic.ErlangError.t
  | ReadUninitializedValue of Diagnostic.read_uninitialized_value
  | JavaCastError of Diagnostic.cast_err
[@@deriving compare, equal, yojson_of]

val pp : F.formatter -> t -> unit

val to_diagnostic : t -> Diagnostic.t

val should_report : ?current_path:int ->
  ?instra_hash:(Sil.instr, int) Caml.Hashtbl.t ->
  ?inst:Sil.instr option ->
    ?tag:bool ->
  AbductiveDomain.Summary.summary ->
  Diagnostic.t ->
    [> `DelayReport of t | `ReportNow ]

val add_call :
     CallEvent.t * Location.t
  -> (AbstractValue.t * ValueHistory.t) AbstractValue.Map.t
  -> AbductiveDomain.t
  -> t
  -> (AbstractValue.t * ValueHistory.t) AbstractValue.Map.t
  -> bool
  -> t
  

val reported_casting : (Location.t,bool) Caml.Hashtbl.t