(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd


val checker :
     ?specialization:PulseSummary.t * Specialization.t
  -> PulseSummary.t InterproceduralAnalysis.t
  -> PulseSummary.t option

val is_already_specialized : Specialization.t -> PulseSummary.t -> bool

val list_printer: ('a -> unit) -> 'a list -> unit