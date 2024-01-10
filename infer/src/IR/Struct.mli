(*
 * Copyright (c) 2009-2013, Monoidics ltd.
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format

type field = Fieldname.t * Typ.t * Annot.Item.t [@@deriving compare, equal]

type fields = field list

type java_class_kind = Interface | AbstractClass | NormalClass [@@deriving equal]

type java_class_info =
  { kind: java_class_kind  (** class kind in Java *)
  ; loc: Location.t option
        (** None should correspond to rare cases when it was impossible to fetch the location in
            source file *) }

module Hack : sig
  type kind = Class | Trait

  type t = {kind: kind}
end

(** Type for a structured value. *)
type t = private
  { fields: fields  (** non-static fields *)
  ; statics: fields  (** static fields *)
  ; supers: Typ.Name.t list  (** superclasses *)
  ; objc_protocols: Typ.Name.t list  (** ObjC protocols *)
  ; methods: Procname.t list  (** methods defined *)
  ; exported_objc_methods: Procname.t list  (** methods in ObjC interface, subset of [methods] *)
  ; annots: Annot.Item.t  (** annotations *)
  ; java_class_info: java_class_info option  (** present if and only if the class is Java *)
  ; dummy: bool  (** dummy struct for class including static method *)
  ; source_file: SourceFile.t option  (** source file containing this struct's declaration *)
  ; hack_class_info: Hack.t option  (** present if and only if the class is Hack *) }

type lookup = Typ.Name.t -> t option

val is_java_abstract : t -> bool

val is_java_interface : t -> bool

val is_java_normal : t -> bool

val pp_field : Pp.env -> F.formatter -> field -> unit

val pp : Pp.env -> Typ.Name.t -> F.formatter -> t -> unit
(** Pretty print a struct type. *)

val internal_mk_struct :
     ?default:t
  -> ?fields:fields
  -> ?statics:fields
  -> ?methods:Procname.t list
  -> ?exported_objc_methods:Procname.t list
  -> ?supers:Typ.Name.t list
  -> ?objc_protocols:Typ.Name.t list
  -> ?annots:Annot.Item.t
  -> ?java_class_info:java_class_info
  -> ?hack_class_info:Hack.t
  -> ?dummy:bool
  -> ?source_file:SourceFile.t
  -> Typ.name
  -> t
(** Construct a struct_typ, normalizing field types *)

val get_extensible_array_element_typ : lookup:lookup -> Typ.t -> Typ.t option
(** the element typ of the final extensible array in the given typ, if any *)

type field_info = {typ: Typ.t; annotations: Annot.Item.t; is_static: bool}

val get_field_info : lookup:lookup -> Fieldname.t -> Typ.t -> field_info option
(** Lookup for info associated with the field [fn]. None if [typ] has no field named [fn] *)

val fld_typ_opt : lookup:lookup -> Fieldname.t -> Typ.t -> Typ.t option
(** If a struct type with field f, return Some (the type of f). If not, return None. *)

val fld_typ : lookup:lookup -> default:Typ.t -> Fieldname.t -> Typ.t -> Typ.t
(** If a struct type with field f, return the type of f. If not, return the default type if given,
    otherwise raise an exception *)

val get_field_type_and_annotation :
  lookup:lookup -> Fieldname.t -> Typ.t -> (Typ.t * Annot.Item.t) option
(** Return the type of the field [fn] and its annotation, None if [typ] has no field named [fn] *)

val merge : Typ.Name.t -> newer:t -> current:t -> t
(** best effort directed merge of two structs for the same typename *)

val is_not_java_interface : t -> bool
(** check that a struct either defines a non-java type, or a non-java-interface type (abstract or
    normal class) *)

val get_source_file : t -> SourceFile.t option

val is_hack_class : t -> bool

val get_all_supers : t -> Typ.name list

val is_hack_trait : t -> bool [@@warning "-unused-value-declaration"]

module Normalizer : HashNormalizer.S with type t = t
