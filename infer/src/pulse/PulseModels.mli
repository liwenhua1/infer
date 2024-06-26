(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)
open! IStd
open PulseModelsImport

val dispatch :
  Tenv.t -> Procname.t -> PulseValuePath.t ProcnameDispatcher.Call.FuncArg.t list -> model option
