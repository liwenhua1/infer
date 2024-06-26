(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module L = Logging
open PulseBasicInterface
open PulseDomainInterface
open PulseOperationResult.Import
open PulseModelsImport
module DSL = PulseModelsDSL

let read_boxed_string_value address astate =
  let open IOption.Let_syntax in
  let hackString = Typ.HackClass (HackClassName.make "HackString") in
  let field = Fieldname.make hackString "val" in
  let* box_val, _ = Memory.find_edge_opt address (FieldAccess field) astate in
  let* string_val, _ = Memory.find_edge_opt box_val Dereference astate in
  AddressAttributes.get_const_string string_val astate


let read_boxed_string_value_dsl aval : string DSL.model_monad =
  (* we cut the current path if no constant string is found *)
  let open PulseModelsDSL.Syntax in
  let* opt_string = exec_operation (read_boxed_string_value (fst aval)) in
  Option.value_map opt_string ~default:unreachable ~f:ret


let hack_dim_field_get this_obj_dbl_ptr (field_string_obj, _) : model =
 fun {path; location; ret} astate ->
  match read_boxed_string_value field_string_obj astate with
  | Some string_val ->
      (* TODO: add a move up in the class hierarchy to find the right field declaration *)
      let field = TextualSil.wildcard_sil_fieldname Textual.Lang.Hack string_val in
      let<*> astate, this_val =
        PulseOperations.eval_access path Read location this_obj_dbl_ptr Dereference astate
      in
      let<+> astate, field_val =
        PulseOperations.eval_access path Read location this_val (FieldAccess field) astate
      in
      let ret_id, _ = ret in
      PulseOperations.write_id ret_id field_val astate
  | None ->
      (* TODO: invalidate the access if the string field is unknown *)
      Logging.d_printfln "reading field failed" ;
      astate |> Basic.ok_continue


let hack_dim_field_get_or_null this_obj_dbl_ptr field : model =
 fun ({path; location; ret= ret_id, _} as model_data) astate ->
  let<*> astate, (this_obj, _) =
    PulseOperations.eval_access path Read location this_obj_dbl_ptr Dereference astate
  in
  (* Case 1: this_obj is a null ptr *)
  let astate1 =
    let<++> astate = PulseArithmetic.prune_eq_zero this_obj astate in
    let null_ret = (AbstractValue.mk_fresh (), Hist.single_call path location "null ptr case") in
    PulseOperations.write_id ret_id null_ret astate
  in
  (* Case 2: this_obj is not null in which case we call the regular hack_dim_field_get *)
  let astate2 =
    let<**> astate = PulseArithmetic.prune_ne_zero this_obj astate in
    hack_dim_field_get this_obj_dbl_ptr field model_data astate
  in
  astate1 @ astate2


let payload_of_arg arg =
  let {ProcnameDispatcher.Call.FuncArg.arg_payload= addr} = arg in
  addr


let payloads_of_args args = List.map ~f:payload_of_arg args

let mk_hack_field clazz field = Fieldname.make (Typ.HackClass (HackClassName.make clazz)) field

let load_field path field location obj astate =
  let* astate, field_addr =
    PulseOperations.eval_access path Read location obj (FieldAccess field) astate
  in
  let+ astate, field_val =
    PulseOperations.eval_access path Read location field_addr Dereference astate
  in
  (astate, field_addr, field_val)


let await_hack_value v astate = AddressAttributes.hack_async_await v astate

let await_hack_value_dsl aval : unit DSL.model_monad =
  fst aval |> await_hack_value |> DSL.Syntax.exec_command


let hack_await (argv, hist) : model =
 fun {ret= ret_id, _} astate ->
  let astate = await_hack_value argv astate in
  PulseOperations.write_id ret_id (argv, hist) astate |> Basic.ok_continue


(* vecs, similar treatment of Java collections, though these are value types
   Should be shared with dict (and keyset) but will generalise later.
   We have an integer size field (rather than just an empty flag) and a
   last_read field, which is 1 or 2 if we last produced the fst or snd field
   as the result of an index operation. This is used to alternate returned values
   so as to remove paths in which we return the same value repeatedly, which leads
   to false awaitable positives because the *other* value is never awaited.
   TODO: a more principled approach to collections of resources.
*)
module Vec = struct
  let class_name = "HackVec"

  let fst_field = mk_hack_field class_name "__infer_model_backing_vec_fst"

  let snd_field = mk_hack_field class_name "__infer_model_backing_vec_snd"

  let size_field = mk_hack_field class_name "__infer_model_backing_vec_size"

  let last_read_field = mk_hack_field class_name "__infer_model_backing_last_read"

  let new_vec_dsl args : DSL.aval DSL.model_monad =
    let open DSL.Syntax in
    let actual_size = List.length args in
    let typ = Typ.mk_struct TextualSil.hack_vec_type_name in
    let* vec = mk_fresh ~model_desc:"new_vec" in
    let* () = add_dynamic_type typ vec in
    let* size = mk_fresh ~model_desc:"new_vec.size" in
    let* last_read = mk_fresh ~model_desc:"new_vec.last_read" in
    let* dummy = mk_fresh ~model_desc:"new_vec.dummy" in
    let* () = write_deref_field ~ref:vec size_field ~obj:size in
    let* () = write_deref_field ~ref:vec last_read_field ~obj:last_read in
    let* () =
      match args with
      | [] ->
          let* () = write_deref_field ~ref:vec fst_field ~obj:dummy in
          write_deref_field ~ref:vec snd_field ~obj:dummy
      | arg1 :: rest -> (
          let* () = write_deref_field ~ref:vec fst_field ~obj:arg1 in
          match rest with
          | [] ->
              write_deref_field ~ref:vec snd_field ~obj:dummy
          | arg2 :: rest -> (
              let* () = write_deref_field ~ref:vec snd_field ~obj:arg2 in
              match rest with
              | [] ->
                  ret ()
                  (* Do "fake" await on the values we drop on the floor. TODO: mark reachable too? *)
              | rest ->
                  list_iter rest ~f:await_hack_value_dsl ) )
    in
    let* () = and_eq_int size (IntLit.of_int actual_size) in
    let* () = and_eq_int dummy (IntLit.of_int 9) in
    ret vec


  let new_vec args : model =
    let values = payloads_of_args args in
    let open DSL.Syntax in
    start_model
    @@ let* vec = new_vec_dsl values in
       assign_ret vec


  let vec_from_async _dummy ((vaddr, _vhist) as v) : model =
   fun {path; location; ret= ret_id, _} astate ->
    (* let event = Hist.call_event path location "Vec\from_async" in *)
    L.d_printfln "Called vec from async" ;
    let<*> astate, _, (fst_val, _) = load_field path fst_field location v astate in
    let<*> astate, _, (snd_val, _) = load_field path snd_field location v astate in
    let astate = await_hack_value fst_val astate in
    let astate = await_hack_value snd_val astate in
    let astate = PulseOperations.allocate Attribute.HackAsync location vaddr astate in
    let astate = PulseOperations.write_id ret_id v astate in
    astate |> Basic.ok_continue


  let get_vec argv index : unit DSL.model_monad =
    let open DSL.Syntax in
    let* ret_val = mk_fresh ~model_desc:"vec index" in
    let* new_last_read_val = mk_fresh ~model_desc:"vec index" in
    let* size_val = eval_deref_access Read argv (FieldAccess size_field) in
    let* fst_val = eval_deref_access Read argv (FieldAccess fst_field) in
    let* snd_val = eval_deref_access Read argv (FieldAccess snd_field) in
    let* last_read_val = eval_deref_access Read argv (FieldAccess last_read_field) in
    let* () = write_deref_field ~ref:argv last_read_field ~obj:new_last_read_val in
    let* () = prune_binop ~negated:false Binop.Lt (aval_operand index) (aval_operand size_val) in
    let* () =
      (* Don't return dummy value *)
      prune_binop ~negated:true Binop.Eq (aval_operand ret_val)
        (ConstOperand (Cint (IntLit.of_int 9)))
    in
    (* TODO: work out how to incorporate type-based, or at least nullability, assertions on ret_val *)
    let case1 : unit DSL.model_monad =
      (* case 1: return is some value equal to neither field
          In this case, we leave the last_read_val field unchanged
          And we also, to avoid false positives, do a fake await of the fst and snd fields
      *)
      let* () = await_hack_value_dsl fst_val in
      let* () = await_hack_value_dsl snd_val in
      let* () = prune_binop ~negated:true Eq (aval_operand ret_val) (aval_operand fst_val) in
      let* () = prune_binop ~negated:true Eq (aval_operand ret_val) (aval_operand snd_val) in
      let* () =
        prune_binop ~negated:false Eq (aval_operand new_last_read_val) (aval_operand last_read_val)
      in
      assign_ret ret_val
    in
    let case2 : unit DSL.model_monad =
      (* case 2: given element is equal to fst_field *)
      let* () =
        prune_binop ~negated:false Eq (aval_operand last_read_val) (ConstOperand (Cint IntLit.two))
      in
      let* () = prune_binop ~negated:false Eq (aval_operand ret_val) (aval_operand fst_val) in
      let* () =
        prune_binop ~negated:false Eq (aval_operand new_last_read_val)
          (ConstOperand (Cint IntLit.one))
      in
      assign_ret ret_val
    in
    let case3 : unit DSL.model_monad =
      (* case 3: given element is equal to snd_field *)
      let* () =
        prune_binop ~negated:false Eq (aval_operand last_read_val) (ConstOperand (Cint IntLit.one))
      in
      let* () = prune_binop ~negated:false Eq (aval_operand ret_val) (aval_operand snd_val) in
      let* () =
        prune_binop ~negated:false Eq (aval_operand new_last_read_val)
          (ConstOperand (Cint IntLit.two))
      in
      assign_ret ret_val
    in
    disjuncts [case1; case2; case3]


  let hack_dim_array_get vec args : unit DSL.model_monad =
    let open DSL.Syntax in
    match args with
    | [key] ->
        let field = mk_hack_field "HackInt" "val" in
        let* index = eval_deref_access Read key (FieldAccess field) in
        get_vec vec index
    | _ ->
        L.d_printfln "Vec.hack_dim_array_get expects only 1 key argument" ;
        disjuncts []


  (*
  See also $builtins.hack_array_cow_append in lib/hack/models.sil
  Model of set is very like that of append, since it ignores the index
  *)
  let hack_array_cow_set_dsl vec args : unit DSL.model_monad =
    let open DSL.Syntax in
    match args with
    | [_key; value] ->
        let* v_fst = eval_deref_access Read vec (FieldAccess fst_field) in
        let* v_snd = eval_deref_access Read vec (FieldAccess snd_field) in
        let* () = await_hack_value_dsl v_fst in
        let* new_vec = new_vec_dsl [v_snd; value] in
        let* size = eval_deref_access Read vec (FieldAccess size_field) in
        let* () = write_deref_field ~ref:new_vec size_field ~obj:size in
        (* overwrite default size of 2 *)
        assign_ret new_vec
    | _ ->
        L.d_printfln "Vec.hack_array_cow_set expects 1 key and 1 value arguments" ;
        unreachable
end

let get_static_companion type_name astate =
  let pvar = Pvar.mk_global (Mangled.mangled (Typ.Name.name type_name) "STATIC") in
  let var = Var.of_pvar pvar in
  (* we chose on purpose to not abduce [pvar] because we don't want to make a disjunctive case
     if it is already assigned or not. This is problematic when the caller already defines the
     variable because the Pulse summary application will not detect that the variable is set
     both in the callee and the caller. But this is fine as long as both functions perform the
     same initialization of the variable. *)
  match AbductiveDomain.Stack.find_opt var astate with
  | Some (addr, _) ->
      (addr, astate)
  | None ->
      let addr = AbstractValue.mk_fresh () in
      let astate = AbductiveDomain.Stack.add var (addr, ValueHistory.epoch) astate in
      let static_type_name = Typ.Name.Hack.static_companion type_name in
      let typ = Typ.mk_struct static_type_name in
      let astate = PulseOperations.add_dynamic_type typ addr astate in
      (addr, astate)


let lazy_class_initialize size_exp : model =
 fun {path; location; ret= ret_id, _} astate ->
  let type_name =
    match size_exp with
    | Exp.Sizeof {typ= {desc= Typ.Tstruct type_name}} ->
        type_name
    | _ ->
        L.die InternalError
          "lazy_class_initialize: the Hack frontend should never generate such argument type"
  in
  let addr, astate = get_static_companion type_name astate in
  let hist = Hist.single_call path location "lazy_class_initialize" in
  PulseOperations.write_id ret_id (addr, hist) astate |> Basic.ok_continue


let get_static_class (addr, _) : model =
 fun {path; location; ret= ret_id, _} astate ->
  match AbductiveDomain.AddressAttributes.get_dynamic_type addr astate with
  | Some {desc= Tstruct type_name} ->
      let addr, astate = get_static_companion type_name astate in
      let hist = Hist.single_call path location "get_static_class" in
      PulseOperations.write_id ret_id (addr, hist) astate |> Basic.ok_continue
  | _ ->
      AbductiveDomain.add_need_dynamic_type_specialization addr astate |> Basic.ok_continue


module Dict = struct
  (* We model dict/shape keys as fields. This is a bit unorthodox in Pulse, but we need
     maximum precision on this ubiquitous Hack data structure. *)

  let field_of_string_value value : Fieldname.t DSL.model_monad =
    let open DSL.Syntax in
    let* string = read_boxed_string_value_dsl value in
    TextualSil.wildcard_sil_fieldname Textual.Lang.Hack string |> ret


  let get_bindings values : (Fieldname.t * DSL.aval) list DSL.model_monad =
    let open DSL.Syntax in
    let chunked = List.chunks_of ~length:2 values in
    list_filter_map chunked ~f:(function
      | [string; value] ->
          let* field = field_of_string_value string in
          ret (Some (field, value))
      | _ ->
          ret None )


  (* TODO: handle integers keys *)
  let new_dict args : model =
    let open DSL.Syntax in
    start_model
    @@ let* bindings = payloads_of_args args |> get_bindings in
       let* dict = mk_fresh ~model_desc:"new_dict" in
       let typ = Typ.mk_struct TextualSil.hack_dict_type_name in
       let* () = add_dynamic_type typ dict in
       let* () =
         list_iter bindings ~f:(fun (field, value) -> write_deref_field ~ref:dict field ~obj:value)
       in
       assign_ret dict


  (* TODO: handle the situation where we have mix of dict and vec *)
  let hack_array_cow_set_dsl dict args : unit DSL.model_monad =
    let open DSL.Syntax in
    (* args = [key1; key2; ...; key; value] *)
    let len_args = List.length args in
    match List.split_n args (len_args - 2) with
    | keys, [key; value] ->
        let* copy = deep_copy ~depth_max:1 dict in
        let* inner_dict =
          list_fold keys ~init:copy ~f:(fun dict key ->
              let* field = field_of_string_value key in
              let* inner_dict = eval_deref_access Read dict (FieldAccess field) in
              let* copied_inned_dict = deep_copy ~depth_max:1 inner_dict in
              let* () = write_deref_field ~ref:dict field ~obj:copied_inned_dict in
              ret copied_inned_dict )
        in
        let* field = field_of_string_value key in
        let* () = write_deref_field ~ref:inner_dict field ~obj:value in
        assign_ret copy
    | _ when List.length args > 2 ->
        L.d_printfln "multidimensional copy on write not implemented yet" ;
        unreachable
    | _ ->
        L.die InternalError "should not happen"


  let hack_dim_array_get dict keys : unit DSL.model_monad =
    let open DSL.Syntax in
    (* TODO: a key for a non-vec could be also a int *)
    let* value =
      list_fold keys ~init:dict ~f:(fun dict key ->
          let* field = field_of_string_value key in
          eval_deref_access Read dict (FieldAccess field) )
    in
    assign_ret value
end

let hack_array_cow_set this args : model =
  let open DSL.Syntax in
  start_model
  @@
  let this = payload_of_arg this in
  let args = payloads_of_args args in
  dynamic_dispatch this
    ~cases:
      [ (TextualSil.hack_dict_type_name, Dict.hack_array_cow_set_dsl this args)
      ; (TextualSil.hack_vec_type_name, Vec.hack_array_cow_set_dsl this args) ]


let hack_dim_array_get this args : model =
  let open DSL.Syntax in
  start_model
  @@
  let this = payload_of_arg this in
  let args = payloads_of_args args in
  dynamic_dispatch this
    ~cases:
      [ (TextualSil.hack_dict_type_name, Dict.hack_dim_array_get this args)
      ; (TextualSil.hack_vec_type_name, Vec.hack_dim_array_get this args) ]


let matchers : matcher list =
  let open ProcnameDispatcher.Call in
  [ -"$builtins" &:: "nondet" <>$$--> Basic.nondet ~desc:"nondet"
  ; +BuiltinDecl.(match_builtin __lazy_class_initialize) <>$ capt_exp $--> lazy_class_initialize
  ; -"$builtins" &:: "hhbc_await" <>$ capt_arg_payload $--> hack_await
  ; -"$builtins" &:: "hack_dim_field_get" <>$ capt_arg_payload $+ capt_arg_payload
    $--> hack_dim_field_get
  ; -"$builtins" &:: "hack_dim_field_get_or_null" <>$ capt_arg_payload $+ capt_arg_payload
    $--> hack_dim_field_get_or_null
  ; -"$builtins" &:: "hack_dim_array_get" <>$ capt_arg $++$--> hack_dim_array_get
  ; -"$builtins" &:: "hack_array_get" <>$ capt_arg $++$--> hack_dim_array_get
  ; -"$builtins" &:: "hack_array_cow_set" <>$ capt_arg $++$--> hack_array_cow_set
  ; -"$builtins" &:: "hack_new_dict" &::.*++> Dict.new_dict
  ; -"$builtins" &:: "hhbc_new_vec" &::.*++> Vec.new_vec
  ; -"$builtins" &:: "hack_get_class" <>$ capt_arg_payload
    $--> Basic.id_first_arg ~desc:"hack_get_class"
    (* not clear why HackC generate this builtin call *)
  ; -"$builtins" &:: "hhbc_class_get_c" <>$ capt_arg_payload $--> get_static_class
    (* we should be able to model that directly in Textual once specialization will be stronger *)
  ; -"$builtins" &:: "hack_get_static_class" <>$ capt_arg_payload $--> get_static_class
  ; -"$root" &:: "FlibSL::Vec::from_async" <>$ capt_arg_payload $+ capt_arg_payload
    $--> Vec.vec_from_async ]
  |> List.map ~f:(ProcnameDispatcher.Call.contramap_arg_payload ~f:ValuePath.addr_hist)
