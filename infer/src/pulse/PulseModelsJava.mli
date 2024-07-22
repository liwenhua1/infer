(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open PulseModelsImport
open PulseBasicInterface
open PulseDomainInterface
module Cplusplus = PulseModelsCpp
module GenericArrayBackedCollection = PulseModelsGenericArrayBackedCollection


val load_field :
     PathContext.t
  -> Fieldname.t
  -> Location.t
  -> AbstractValue.t * ValueHistory.t
  -> AbductiveDomain.t
  -> (AbductiveDomain.t * (AbstractValue.t * ValueHistory.t) * (AbstractValue.t * ValueHistory.t))
     AccessResult.t

val matchers : matcher list

val instance_apply_before_abv : (Procname.t, AbstractValue.t list) Caml.Hashtbl.t
val should_analyse_cast : (Procname.t, bool) Caml.Hashtbl.t