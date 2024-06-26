(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format
module SatUnsat = PulseSatUnsat
module ValueHistory = PulseValueHistory
exception Foo of string

(* NOTE: using [Var] for [AbstractValue] here since this is how "abstract values" are interpreted,
   in particular as far as arithmetic is concerned *)
module Var = PulseAbstractValue

(** {2 Arithmetic solver}

    Build formulas from SIL and tries to decide if they are (mostly un-)satisfiable. *)

type t [@@deriving compare, equal, yojson_of]

val pp : F.formatter -> t -> unit

val get_all_instance_constrains : Var.t -> t -> Typ.t list * Typ.t list
val get_number_instanceof : t -> Var.t-> int

val pp_with_pp_var : (F.formatter -> Var.t -> unit) -> F.formatter -> t -> unit
  [@@warning "-unused-value-declaration"]
(** only used for unit tests *)
val checking_instanceof_var: bool -> Var.t -> t -> bool * Var.t * Typ.t option
val ty_name : Typ.t -> Typ.name
val get_all_instance_pvar : t -> Var.t list
val find_last_subclass : Tenv.t -> Typ.name -> Typ.t list -> Typ.name * bool
val check_not_instance : Tenv.t -> Typ.name -> Typ.name list -> bool * Typ.name list
val type_list_conversion : Typ.t list -> Typ.name list
val check_dynamic_type_sat : Typ.name -> Typ.name list * Typ.name list -> Tenv.t -> bool
type function_symbol = Unknown of Var.t | Procname of Procname.t [@@deriving compare, equal]

type operand =
  | AbstractValueOperand of Var.t
  | ConstOperand of Const.t
  | FunctionApplicationOperand of {f: function_symbol; actuals: Var.t list}
[@@deriving compare, equal]

val pp_operand : F.formatter -> operand -> unit

(** {3 Build formulas} *)

(** some operations will return a set of new facts discovered that are relevant to communicate to
    the memory domain *)
type new_eq = EqZero of Var.t | Equal of Var.t * Var.t

val pp_new_eq : F.formatter -> new_eq -> unit

type new_eqs = new_eq RevList.t

val ttrue : t

val and_equal : operand -> operand -> t -> (t * new_eqs) SatUnsat.t

val and_equal_vars : Var.t -> Var.t -> t -> (t * new_eqs) SatUnsat.t
(** [and_equal_vars v1 v2 phi] is
    [and_equal (AbstractValueOperand v1) (AbstractValueOperand v2) phi] *)

val and_not_equal : operand -> operand -> t -> (t * new_eqs) SatUnsat.t

val and_equal_instanceof : Var.t -> Var.t -> Typ.t -> t -> (t * new_eqs) SatUnsat.t

val and_less_equal : operand -> operand -> t -> (t * new_eqs) SatUnsat.t

val and_less_than : operand -> operand -> t -> (t * new_eqs) SatUnsat.t

val and_equal_unop : Var.t -> Unop.t -> operand -> t -> (t * new_eqs) SatUnsat.t

val and_equal_binop : Var.t -> Binop.t -> operand -> operand -> t -> (t * new_eqs) SatUnsat.t

val and_is_int : Var.t -> t -> (t * new_eqs) SatUnsat.t

val prune_binop : negated:bool -> Binop.t -> operand -> operand -> t -> (t * new_eqs) SatUnsat.t

(** {3 Operations} *)

val normalize : Tenv.t -> get_dynamic_type:(Var.t -> Typ.t option) -> t -> (t * new_eqs) SatUnsat.t
(** think a bit harder about the formula *)

val simplify :
     Tenv.t
  -> get_dynamic_type:(Var.t -> Typ.t option)
  -> precondition_vocabulary:Var.Set.t
  -> keep:Var.Set.t
  -> t
  -> (t * Var.Set.t * new_eqs) SatUnsat.t

val is_known_zero : t -> Var.t -> bool

val is_known_non_pointer : t -> Var.t -> bool

val is_manifest : is_allocated:(Var.t -> bool) -> t -> bool
(** Some types or errors detected by Pulse require that the state be *manifest*, which corresponds
    to the fact that the error can happen in *any reasonable* calling context (see below). If not,
    the error is flagged as *latent* and not reported until it becomes manifest.

    A state is *manifest* when its path condition (here meaning the conjunction of conditions
    encountered in [if] statements, loop conditions, etc., i.e. anything in a {!IR.Sil.Prune} node)
    is either a) empty or b) comprised only of facts of the form [p>0] or [p≠0] where [p] is known
    to be allocated. The latter condition captures the idea that addresses being valid pointers in
    memory should not deter us from reporting any error that we find on that program path as it is
    somewhat the happy/expected case. The unhappy/unexpected case here would be to report errors
    that require a pointer to be invalid or null in the precondition; we do not want to report such
    errors until we see that there exists a calling context in which the pointer is indeed invalid
    or null! But, to reiterate, we do want to report errors that only have valid pointers in their
    precondition. *)

val get_var_repr : t -> Var.t -> Var.t
(** get the canonical representative for the variable according to the equality relation *)

val and_callee_pre :
     (Var.t * ValueHistory.t) Var.Map.t
  -> t
  -> callee:t
  -> ((Var.t * ValueHistory.t) Var.Map.t * t * new_eqs) SatUnsat.t

val and_callee_post :
     (Var.t * ValueHistory.t) Var.Map.t
  -> t
  -> callee:t
  -> ((Var.t * ValueHistory.t) Var.Map.t * t * new_eqs) SatUnsat.t

val fold_variables : (t, Var.t, 'acc) Container.fold
(** note: each variable mentioned in the formula is visited at least once, possibly more *)

val absval_of_int : t -> IntLit.t -> Var.t
(** Get or create an abstract value ([Var.t] is [AbstractValue.t]) associated with a constant
    {!IR.IntLit.t}. The idea is that clients will record in the abstract state that the returned [t]
    is equal to the given integer. If the same integer is queried later on then this module will
    return the same abstract variable. *)

val init_with_instanceof : Var.t -> Typ.t -> t -> t

val init_instanceof : ('a * Typ.t * (Var.t * 'b)) list -> t -> t