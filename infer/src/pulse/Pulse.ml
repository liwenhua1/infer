(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format
module L = Logging
module IRAttributes = Attributes
open PulseBasicInterface
open PulseDomainInterface
open PulseOperationResult.Import




(** raised when we detect that pulse is using too much memory to stop the analysis of the current
    procedure *)
exception AboutToOOM
exception Listhd

let instr_latent_hash : (Sil.instr, int) Caml.Hashtbl.t= Caml.Hashtbl.create 1000


let current_path_table : (Procname.t,int) Caml.Hashtbl.t= Caml.Hashtbl.create 1000








let rec list_printer f alist = 
  match alist with
  | [] -> print_endline ""
  | x::xs -> f x ; list_printer f xs 

let report_topl_errors proc_desc err_log summary =
  let f = function
    | ContinueProgram astate ->
        let pulse_is_manifest = PulseArithmetic.is_manifest astate in
        AbductiveDomain.Topl.report_errors proc_desc err_log ~pulse_is_manifest astate
    | _ ->
        ()
  in
  List.iter ~f summary


let is_hack_async pname =
  Option.exists (IRAttributes.load pname) ~f:(fun attrs -> attrs.ProcAttributes.is_hack_async)


let is_not_implicit_or_copy_ctor_assignment pname =
  not
    (Option.exists (IRAttributes.load pname) ~f:(fun attrs ->
         attrs.ProcAttributes.is_cpp_implicit || attrs.ProcAttributes.is_cpp_copy_ctor
         || attrs.ProcAttributes.is_cpp_copy_assignment ) )


let is_non_deleted_copy pname =
  (* TODO: Default is set to true for now because we can't get the attributes of library calls right now. *)
  Option.value_map ~default:true (IRAttributes.load pname) ~f:(fun attrs ->
      attrs.ProcAttributes.is_cpp_copy_ctor && not attrs.ProcAttributes.is_cpp_deleted )


let is_type_copiable tenv typ =
  match typ with
  | {Typ.desc= Tstruct name} | {Typ.desc= Tptr ({desc= Tstruct name}, _)} -> (
    match Tenv.lookup tenv name with
    | None | Some {dummy= true} ->
        true
    | Some {methods} ->
        List.exists ~f:is_non_deleted_copy methods )
  | _ ->
      true


let get_loc_instantiated pname =
  IRAttributes.load pname |> Option.bind ~f:ProcAttributes.get_loc_instantiated


let report_unnecessary_copies proc_desc err_log non_disj_astate =
  let pname = Procdesc.get_proc_name proc_desc in
  if is_not_implicit_or_copy_ctor_assignment pname then
    PulseNonDisjunctiveDomain.get_copied
      ~ref_formals:(Procdesc.get_passed_by_ref_formals proc_desc)
      ~ptr_formals:(Procdesc.get_pointer_formals proc_desc)
      non_disj_astate
    |> List.iter ~f:(fun (copied_into, source_typ, source_opt, location, copied_location, from) ->
           let copy_name = Format.asprintf "%a" Attribute.CopiedInto.pp copied_into in
           let is_suppressed = PulseNonDisjunctiveOperations.has_copy_in copy_name in
           let location_instantiated = get_loc_instantiated pname in
           let diagnostic =
             Diagnostic.UnnecessaryCopy
               { copied_into
               ; source_typ
               ; source_opt
               ; location
               ; copied_location
               ; location_instantiated
               ; from }
           in
           PulseReport.report ~is_suppressed ~latent:false proc_desc err_log diagnostic )


let report_unnecessary_parameter_copies tenv proc_desc err_log non_disj_astate =
  let pname = Procdesc.get_proc_name proc_desc in
  if is_not_implicit_or_copy_ctor_assignment pname then
    PulseNonDisjunctiveDomain.get_const_refable_parameters non_disj_astate
    |> List.iter ~f:(fun (param, typ, location) ->
           if is_type_copiable tenv typ then
             let diagnostic =
               if Typ.is_shared_pointer typ then
                 if NonDisjDomain.is_lifetime_extended param non_disj_astate then None
                 else
                   let used_locations = NonDisjDomain.get_loaded_locations param non_disj_astate in
                   Some
                     (Diagnostic.ReadonlySharedPtrParameter {param; typ; location; used_locations})
               else Some (Diagnostic.ConstRefableParameter {param; typ; location})
             in
             Option.iter diagnostic ~f:(fun diagnostic ->
                 PulseReport.report ~is_suppressed:false ~latent:false proc_desc err_log diagnostic ) )


let heap_size () = (Gc.quick_stat ()).heap_words

module PulseTransferFunctions = struct
  module CFG = ProcCfg.ExceptionalNoSinkToExitEdge
  module DisjDomain = AbstractDomain.PairDisjunct (ExecutionDomain) (PathContext)
  module NonDisjDomain = NonDisjDomain

  type analysis_data = PulseSummary.t InterproceduralAnalysis.t

  let get_pvar_formals pname =
    IRAttributes.load pname |> Option.map ~f:ProcAttributes.get_pvar_formals


  let need_closure_specialization astates =
    List.exists astates ~f:(fun res ->
        match PulseResult.ok res with
        | Some
            ( ContinueProgram {AbductiveDomain.need_closure_specialization}
            | ExceptionRaised {AbductiveDomain.need_closure_specialization} ) ->
            need_closure_specialization
        | Some
            ( ExitProgram astate
            | AbortProgram astate
            | LatentAbortProgram {astate}
            | LatentInvalidAccess {astate} ) ->
            AbductiveDomain.Summary.need_closure_specialization astate
        | None ->
            false )


  let reset_need_closure_specialization needed_closure_specialization astates =
    if needed_closure_specialization then
      List.map astates ~f:(fun res ->
          PulseResult.map res ~f:(function
            | ExceptionRaised astate ->
                let astate = AbductiveDomain.set_need_closure_specialization astate in
                ExceptionRaised astate
            | ContinueProgram astate ->
                let astate = AbductiveDomain.set_need_closure_specialization astate in
                ContinueProgram astate
            | ExitProgram astate ->
                let astate = AbductiveDomain.Summary.with_need_closure_specialization astate in
                ExitProgram astate
            | AbortProgram astate ->
                let astate = AbductiveDomain.Summary.with_need_closure_specialization astate in
                AbortProgram astate
            | LatentAbortProgram latent_abort_program ->
                let astate =
                  AbductiveDomain.Summary.with_need_closure_specialization
                    latent_abort_program.astate
                in
                LatentAbortProgram {latent_abort_program with astate}
            | LatentInvalidAccess latent_invalid_access ->
                let astate =
                  AbductiveDomain.Summary.with_need_closure_specialization
                    latent_invalid_access.astate
                in
                LatentInvalidAccess {latent_invalid_access with astate} ) )
    else astates


  let interprocedural_call
      ({InterproceduralAnalysis.analyze_dependency; tenv; proc_desc} as analysis_data) path ret
      callee_pname call_exp func_args call_loc (flags : CallFlags.t) astate =
     
    let actuals =
      List.map func_args ~f:(fun ProcnameDispatcher.Call.FuncArg.{arg_payload; typ} ->
          (ValuePath.addr_hist arg_payload, typ) )
    in
    let call_kind_of call_exp =
      match call_exp with
      | Exp.Closure {captured_vars} ->
          `Closure captured_vars
      | Exp.Var id ->
          `Var id
      | _ ->
          `ResolvedProcname
    in
    let eval_args_and_call callee_pname call_exp astate =
      let formals_opt = get_pvar_formals callee_pname in
      let call_kind = call_kind_of call_exp in
      PulseCallOperations.call tenv path ~caller_proc_desc:proc_desc ~analyze_dependency call_loc
        callee_pname ~ret ~actuals ~formals_opt ~call_kind astate
    in
    match callee_pname with
    | Some callee_pname when not Config.pulse_intraprocedural_only ->
        (* [needed_closure_specialization] = current function already needs specialization before
           the upcoming call (i.e. we did not have enough information to sufficiently
           specialize a callee). *)
        let needed_closure_specialization = astate.AbductiveDomain.need_closure_specialization in
        (* [astate.need_closure_specialization] is false when entering the call. This is to
           detect calls that need specialization. The value will be set back to true
           (if it was) in the end by [reset_need_closure_specialization] *)
        let astate = AbductiveDomain.unset_need_closure_specialization astate in
        let maybe_call_specialization callee_pname call_exp ((res, _, _) as call_res) =
          if (not needed_closure_specialization) && need_closure_specialization res then (
            L.d_printfln "Trying to closure-specialize %a" Exp.pp call_exp ;
            match
              PulseClosureSpecialization.make_specialized_call_exp analysis_data
                (ValuePath.addr_hist_args func_args)
                callee_pname (call_kind_of call_exp) path call_loc astate
            with
            | Some (callee_pname, call_exp, astate) ->
                L.d_printfln "Succesfully closure-specialized %a@\n" Exp.pp call_exp ;
                let call_res = eval_args_and_call callee_pname call_exp astate in
                (callee_pname, call_exp, call_res)
            | None ->
                L.d_printfln "Failed to closure-specialize %a@\n" Exp.pp call_exp ;
                (callee_pname, call_exp, call_res) )
          else (callee_pname, call_exp, call_res)
        in
        let _, _, (res, _, is_known_call) =
          eval_args_and_call callee_pname call_exp astate
          |> maybe_call_specialization callee_pname call_exp
        in
        (reset_need_closure_specialization needed_closure_specialization res, is_known_call)
    | _ ->
        (* dereference call expression to catch nil issues *)
        ( (let<**> astate, _ =
             if flags.cf_is_objc_block then
               (* We are on an unknown block call, meaning that the block was defined
                  outside the current function and was either passed by the caller
                  as an argument or retrieved from an object. We do not handle blocks
                  inside objects yet so we assume we are in the former case. In this
                  case, we tell the caller that we are missing some information by
                  setting [need_closure_specialization] in the resulting state and the caller
                  will then try to specialize the current function with its available
                  information. *)
               let astate = AbductiveDomain.set_need_closure_specialization astate in
               PulseOperations.eval_deref path ~must_be_valid_reason:BlockCall call_loc call_exp
                 astate
             else
               let astate =
                 if
                   (* this condition may need refining to check that the function comes
                      from the function's parameters or captured variables.
                      The function_pointer_specialization option is there to compensate
                      this / control the specialization's agressivity *)
                   Config.function_pointer_specialization
                   && Language.equal Language.Clang
                        (Procname.get_language (Procdesc.get_proc_name proc_desc))
                 then AbductiveDomain.set_need_closure_specialization astate
                 else astate
               in
               PulseOperations.eval_deref path call_loc call_exp astate
           in
           L.d_printfln "Skipping indirect call %a@\n" Exp.pp call_exp ;
           let astate =
             let arg_values = List.map actuals ~f:(fun ((value, _), _) -> value) in
             PulseOperations.conservatively_initialize_args arg_values astate
           in
           let<++> astate =
             PulseCallOperations.unknown_call tenv path call_loc (SkippedUnknownCall call_exp)
               callee_pname ~ret ~actuals ~formals_opt:None astate
           in
           astate )
        , `UnknownCall )


  (** has an object just gone out of scope? *)
  let get_out_of_scope_object callee_pname actuals (flags : CallFlags.t) =
    (* injected destructors are precisely inserted where an object goes out of scope *)
    if flags.cf_injected_destructor then
      match (callee_pname, actuals) with
      | Some (Procname.ObjC_Cpp pname), [(Exp.Lvar pvar, typ)]
        when Pvar.is_local pvar && not (Procname.ObjC_Cpp.is_inner_destructor pname) ->
          (* ignore inner destructors, only trigger out of scope on the final destructor call *)
          Some (pvar, typ)
      | _ ->
          None
    else None


  (** [out_of_scope_access_expr] has just gone out of scope and in now invalid *)
  let exec_object_out_of_scope path call_loc (pvar, typ) exec_state =
    match (exec_state : ExecutionDomain.t) with
    | ContinueProgram astate | ExceptionRaised astate ->
        let gone_out_of_scope = Invalidation.GoneOutOfScope (pvar, typ) in
        let++ astate, out_of_scope_base =
          PulseOperations.eval path NoAccess call_loc (Exp.Lvar pvar) astate
        in
        (* invalidate [&x] *)
        PulseOperations.invalidate path
          (StackAddress (Var.of_pvar pvar, ValueHistory.epoch))
          call_loc gone_out_of_scope out_of_scope_base astate
        |> ExecutionDomain.continue
    | AbortProgram _ | ExitProgram _ | LatentAbortProgram _ | LatentInvalidAccess _ ->
        Sat (Ok exec_state)


  let topl_small_step loc procname arguments (return, _typ) exec_state_res =
    let arguments =
      List.map arguments ~f:(fun {ProcnameDispatcher.Call.FuncArg.arg_payload} -> fst arg_payload)
    in
    let return = Var.of_id return in
    let do_astate astate =
      let return = Option.map ~f:fst (Stack.find_opt return astate) in
      let topl_event = PulseTopl.Call {return; arguments; procname} in
      AbductiveDomain.Topl.small_step loc topl_event astate
    in
    let do_one_exec_state (exec_state : ExecutionDomain.t) : ExecutionDomain.t =
      match exec_state with
      | ContinueProgram astate ->
          ContinueProgram (do_astate astate)
      | AbortProgram _
      | LatentAbortProgram _
      | ExitProgram _
      | ExceptionRaised _
      | LatentInvalidAccess _ ->
          exec_state
    in
    List.map ~f:(PulseResult.map ~f:do_one_exec_state) exec_state_res


  let topl_store_step path loc ~lhs ~rhs:_ astate =
    match (lhs : Exp.t) with
    | Lindex (arr, index) ->
        (let** _astate, (aw_array, _history) = PulseOperations.eval path Read loc arr astate in
         let++ _astate, (aw_index, _history) = PulseOperations.eval path Read loc index astate in
         let topl_event = PulseTopl.ArrayWrite {aw_array; aw_index} in
         AbductiveDomain.Topl.small_step loc topl_event astate )
        |> PulseOperationResult.sat_ok
        |> (* don't emit Topl event if evals fail *) Option.value ~default:astate
    | _ ->
        astate


  (* assume that virtual calls are only made on instance methods where it makes sense, in which case
     the receiver is always the first argument if present *)
  let get_receiver _proc_name actuals =
    match actuals with receiver :: _ -> Some receiver | _ -> None


  let get_dynamic_type_name astate v =
    match AbductiveDomain.AddressAttributes.get_dynamic_type_source_file v astate with
    | Some ({desc= Tstruct name}, source_file_opt) ->
        Some (name, source_file_opt)
    | Some (t, _) ->
        L.d_printfln "dynamic type %a of %a is not a Tstruct" (Typ.pp_full Pp.text) t
          AbstractValue.pp v ;
        None
    | None ->
        L.d_printfln "no dynamic type found for %a" AbstractValue.pp v ;
        None


  let find_override exe_env tenv astate receiver proc_name proc_name_opt =
    let tenv_resolve_method tenv type_name proc_name =
      let method_exists proc_name methods = List.mem ~equal:Procname.equal methods proc_name in
      Tenv.resolve_method ~method_exists tenv type_name proc_name
    in
    let open IOption.Let_syntax in
    match get_dynamic_type_name astate receiver with
    | Some (dynamic_type_name, source_file_opt) ->
        (* if we have a source file then do the look up in the (local) tenv
           for that source file instead of in the tenv for the current file *)
        let tenv =
          Option.bind source_file_opt ~f:(Exe_env.get_source_tenv exe_env)
          |> Option.value ~default:tenv
        in
        let+ proc_name = tenv_resolve_method tenv dynamic_type_name proc_name in
        (proc_name, `ExactDevirtualization)
    | None ->
        let+ proc_name =
          if Language.curr_language_is Hack then
            (* contrary to the Java frontend, the Hack frontend does not perform
               static resolution so we have to do it here *)
            let* type_name = Procname.get_class_type_name proc_name in
            tenv_resolve_method tenv type_name proc_name
          else Option.map ~f:Tenv.MethodInfo.mk_class proc_name_opt
        in
        (proc_name, `ApproxDevirtualization)


  let string_of_devirtualization_status = function
    | `ExactDevirtualization ->
        "exactly"
    | `ApproxDevirtualization ->
        "approximately"


  let resolve_virtual_call exe_env tenv astate receiver proc_name_opt =
    Option.map proc_name_opt ~f:(fun proc_name ->
        match find_override exe_env tenv astate receiver proc_name proc_name_opt with
        | Some (info, devirtualization_status) ->
            let proc_name' = Tenv.MethodInfo.get_procname info in
            L.d_printfln "Dynamic dispatch: %a %s resolved to %a" Procname.pp_verbose proc_name
              (string_of_devirtualization_status devirtualization_status)
              Procname.pp_verbose proc_name' ;
            (info, devirtualization_status)
        | None ->
            (Tenv.MethodInfo.mk_class proc_name, `ApproxDevirtualization) )


  let need_dynamic_type_specialization astate receiver_addr =
    AbductiveDomain.add_need_dynamic_type_specialization receiver_addr astate


  (* Hack static methods can be overriden so we need class hierarchy walkup *)
  let resolve_hack_static_method path loc astate tenv proc_name opt_callee_pname =
    let resolve_method tenv type_name proc_name =
      let equal pname1 pname2 =
        String.equal (Procname.get_method pname1) (Procname.get_method pname2)
      in
      let is_already_resolved proc_name =
        (* these methods will never be found in Tenv but we can assume they exist *)
        Option.exists (Procname.get_class_type_name proc_name) ~f:(fun class_name ->
            List.mem ~equal:Typ.Name.equal
              [ TextualSil.hack_mixed_type_name
              ; TextualSil.hack_mixed_static_companion_type_name
              ; TextualSil.hack_builtins_type_name
              ; TextualSil.hack_root_type_name ]
              class_name )
      in
      let method_exists proc_name methods = List.mem ~equal methods proc_name in
      if is_already_resolved proc_name then (
        L.d_printfln "always_implemented %a" Procname.pp proc_name ;
        Some (Tenv.MethodInfo.mk_class proc_name) )
      else Tenv.resolve_method ~method_exists tenv type_name proc_name
    in
    (* In a Hack trait, try to replace [__self__$static] with the static class name where the
       [use] of the trait was located. This information is stored in the additional [self]
       argument hackc added to the trait. *)
    let resolve_self_in_trait astate static_class_name =
      let mangled = Mangled.from_string "self" in
      (* pvar is &self, we need to dereference it to access its dynamic type *)
      let pvar = Pvar.mk mangled proc_name in
      let astate, value = PulseOperations.eval_var path loc pvar astate in
      match
        PulseOperations.eval_access path Read loc value Dereference astate |> PulseResult.ok
      with
      | None ->
          (Some static_class_name, astate)
      | Some (astate, (value, _)) -> (
        match AbductiveDomain.AddressAttributes.get_dynamic_type value astate with
        | None ->
            (* No information is available from the [self] argument at this time, we need to
               wait for specialization *)
            (None, need_dynamic_type_specialization astate value)
        | Some typ ->
            (Typ.name typ, astate) )
    in
    (* If we spot a call on [__parent__$static], we push further and get the parent of
       [__self__$static] *)
    let resolve_parent_in_trait astate static_class_name =
      let self_ty_name, astate = resolve_self_in_trait astate static_class_name in
      (* Now that we have the [self] type, locate its parent *)
      let parent = Option.bind self_ty_name ~f:(Tenv.get_parent tenv) in
      (parent, astate)
    in
    let trait_resolution astate static_class_name =
      let maybe_origin = Typ.Name.Hack.static_companion_origin static_class_name |> Typ.Name.name in
      if String.equal "__self__" maybe_origin then resolve_self_in_trait astate static_class_name
      else if String.equal "__parent__" maybe_origin then
        resolve_parent_in_trait astate static_class_name
      else (Some static_class_name, astate)
    in
    (* Similar to IOption.Let_syntax but threading [astate] along the way *)
    let ( let* ) (opt, env) f = match opt with None -> (None, env) | Some v -> f (v, env) in
    let* callee_pname, astate = (opt_callee_pname, astate) in
    match Procname.get_class_type_name callee_pname with
    | None ->
        (Some (Tenv.MethodInfo.mk_class callee_pname), astate)
    | Some static_class_name ->
        let* static_class_name, astate = trait_resolution astate static_class_name in
        L.d_printfln "hack static dispatch from %a in class name %a" Procname.pp callee_pname
          Typ.Name.pp static_class_name ;
        (resolve_method tenv static_class_name callee_pname, astate)


  let improve_receiver_static_type astate receiver proc_name_opt =
    if Language.curr_language_is Hack then
      let open IOption.Let_syntax in
      let* proc_name = proc_name_opt in
      match AbductiveDomain.AddressAttributes.get_static_type receiver astate with
      | Some typ_name ->
          let improved_proc_name = Procname.replace_class proc_name typ_name in
          L.d_printfln "Progagating declared type to improve callee name: %a replaced by %a"
            Procname.pp proc_name Procname.pp improved_proc_name ;
          Some improved_proc_name
      | _ ->
          proc_name_opt
    else proc_name_opt


  type model_search_result =
    | DoliModel of Procname.t
    | OcamlModel of (PulseModelsImport.model * Procname.t)
    | NoModel

  (* When Hack traits are involved, we need to compute and pass an additional argument that is a
     token to find the right class name for [self].

     [hackc] adds [self] argument at the end of the signature. *)
  let add_self_for_hack_traits astate method_info func_args =
    let hack_kind = Option.bind method_info ~f:Tenv.MethodInfo.get_hack_kind in
    match hack_kind with
    | Some (IsTrait {used}) ->
        let exp, arg_payload, astate =
          let value, astate = PulseModelsHack.get_static_companion used astate in
          let self_id = Ident.create_fresh Ident.kprimed in
          let arg_payload = (value, ValueHistory.epoch) in
          let astate = PulseOperations.write_id self_id arg_payload astate in
          (Exp.Var self_id, arg_payload, astate)
        in
        let static_used = Typ.Name.Hack.static_companion used in
        let typ = Typ.mk_struct static_used |> Typ.mk_ptr in
        let self =
          {PulseAliasSpecialization.FuncArg.exp; typ; arg_payload= ValuePath.Unknown arg_payload}
        in
        (astate, func_args @ [self])
    | Some IsClass | None ->
        (astate, func_args)

    
  let rec dispatch_call_eval_args
      ({InterproceduralAnalysis.tenv; proc_desc; err_log; exe_env} as analysis_data) path ret
      call_exp actuals func_args call_loc flags astate callee_pname : ExecutionDomain.t AccessResult.t list=
      (* print_endline (Exp.to_string call_exp); *)
    let method_info, astate =
      let default_info = Option.map ~f:Tenv.MethodInfo.mk_class callee_pname in
      if flags.CallFlags.cf_virtual then
        match get_receiver callee_pname func_args with
        | None ->
            L.internal_error "No receiver on virtual call" ;
            (default_info, astate)
        | Some {ProcnameDispatcher.Call.FuncArg.arg_payload= receiver} -> (
          match
            improve_receiver_static_type astate (ValuePath.value receiver) callee_pname
            |> resolve_virtual_call exe_env tenv astate (ValuePath.value receiver)
          with
          | Some (info, `ExactDevirtualization) ->
              (Some info, astate)
          | Some (info, `ApproxDevirtualization) ->
              (Some info, need_dynamic_type_specialization astate (ValuePath.value receiver))
          | None ->
              (None, astate) )
      else if Language.curr_language_is Hack then
        (* In Hack, a static method can be inherited *)
        let proc_name = Procdesc.get_proc_name proc_desc in
        resolve_hack_static_method path call_loc astate tenv proc_name callee_pname
      else (default_info, astate)
     
    in   
    let callee_pname = Option.map ~f:Tenv.MethodInfo.get_procname method_info in
    let astate, func_args = add_self_for_hack_traits astate method_info func_args in
    
    let astate =
      match (callee_pname, func_args) with
      | Some callee_pname, [{ProcnameDispatcher.Call.FuncArg.arg_payload= arg}]
        when Procname.is_std_move callee_pname ->
          AddressAttributes.add_one (ValuePath.value arg) StdMoved astate
      | _, _ ->
          astate
    in
    let astate =
      List.fold func_args ~init:astate
        ~f:(fun acc {ProcnameDispatcher.Call.FuncArg.arg_payload= arg; exp} ->
          match exp with
          | Cast (typ, _) when Typ.is_rvalue_reference typ ->
              AddressAttributes.add_one (ValuePath.value arg) StdMoved acc
          | _ ->
              acc )
    in
    
    let model =
      match callee_pname with
      | Some callee_pname -> (
        match DoliToTextual.matcher callee_pname with
        | Some procname ->
            DoliModel procname
        | None ->
            PulseModels.dispatch tenv callee_pname func_args
            |> Option.value_map ~default:NoModel ~f:(fun model -> OcamlModel (model, callee_pname))
        )
      | None ->
          (* unresolved function pointer, etc.: skip *)
          NoModel
    in
    (* do interprocedural call then destroy objects going out of scope *)
    let exec_states_res, call_was_unknown =
      match model with
      | OcamlModel (model, callee_procname) ->
        
          L.d_printfln "Found ocaml model for call@\n" ;
          let astate =
            let arg_values =
              List.map func_args ~f:(fun {ProcnameDispatcher.Call.FuncArg.arg_payload= value} ->
                  ValuePath.value value )
            in
            PulseOperations.conservatively_initialize_args arg_values astate
          in
          ( model
              { analysis_data
              ; dispatch_call_eval_args
              ; path
              ; callee_procname
              ; location= call_loc
              ; ret }
              astate
          , `KnownCall )
      | DoliModel callee_pname ->
     
          L.d_printfln "Found doli model %a for call@\n" Procname.pp callee_pname ;
          PerfEvent.(log (fun logger -> log_begin_event logger ~name:"pulse interproc call" ())) ;
          let r =
            interprocedural_call analysis_data path ret (Some callee_pname) call_exp func_args
              call_loc flags astate
          in
          PerfEvent.(log (fun logger -> log_end_event logger ())) ;
          r
      | NoModel ->
        (*goes to here*)
          PerfEvent.(log (fun logger -> log_begin_event logger ~name:"pulse interproc call" ())) ;
          let r =
            interprocedural_call analysis_data path ret callee_pname call_exp func_args call_loc
              flags astate
          in
          PerfEvent.(log (fun logger -> log_end_event logger ())) ;
          r
    in
    (*haven't reach post*)
    let exec_states_res =
     
      let one_state exec_state_res =
        let* exec_state = exec_state_res in
        match exec_state with
        | ContinueProgram astate ->
          
            let call_event =
              match callee_pname with
              | None ->
                  Either.First call_exp
              | Some proc_name ->
                  Either.Second proc_name
            in
            let call_was_unknown =
              match call_was_unknown with (`UnknownCall) -> true | `KnownCall -> false
            in
            
            let+ astate =
              
              let astate_after_call =
                (* TODO: move to PulseModelsHack *)
                match callee_pname with
                | Some proc_name when is_hack_async proc_name -> (
                    L.d_printfln "did return from asynccall of %a, ret=%a" Procname.pp proc_name
                      Ident.pp (fst ret) ;
                    match PulseOperations.read_id (fst ret) astate with
                    | None ->
                        L.d_printfln "couldn't find ret in state" ;
                       
                        astate
                    | Some (rv, _) ->
                        L.d_printfln "return value %a" AbstractValue.pp rv ;
                         
                        PulseOperations.allocate Attribute.HackAsync call_loc rv astate )
                | _ ->
                  
                    astate
              in
              PulseTaintOperations.call tenv path call_loc ret ~call_was_unknown call_event
                func_args astate_after_call
            in
            (* AbductiveDomain.pp F.std_formatter astate;  *)
            (*result calculated in astate*)
            ContinueProgram astate
        | ( ExceptionRaised _
          | ExitProgram _
          | AbortProgram _
          | LatentAbortProgram _
          | LatentInvalidAccess _ ) as exec_state ->
            Ok exec_state
      in
     
      List.map exec_states_res ~f:one_state;
    in
    
    let exec_states_res =
      if Topl.is_active () then
        match callee_pname with
        | Some callee_pname ->
            topl_small_step call_loc callee_pname
              (ValuePath.addr_hist_args func_args)
              ret exec_states_res
        | None ->
            (* skip, as above for non-topl *) exec_states_res
      else exec_states_res
    in
    let exec_states_res =
      match get_out_of_scope_object callee_pname actuals flags with
      | Some pvar_typ ->
          L.d_printfln "%a is going out of scope" Pvar.pp_value (fst pvar_typ) ;
          List.filter_map exec_states_res ~f:(fun exec_state ->
              exec_state >>>= exec_object_out_of_scope path call_loc pvar_typ |> SatUnsat.sat )
      | None ->
          exec_states_res
    in
    
    if Option.exists callee_pname ~f:IRAttributes.is_no_return then
      List.filter_map exec_states_res ~f:(fun exec_state_res ->
          (let+ exec_state = exec_state_res in
           PulseSummary.force_exit_program tenv proc_desc err_log call_loc exec_state
           |> SatUnsat.sat )
          |> PulseResult.of_some )
    else exec_states_res

  let fun_is_known
    ({InterproceduralAnalysis.tenv; proc_desc;exe_env} as analysis_data) path ret
    call_exp func_args call_loc flags astate callee_pname =
    (* print_endline (Exp.to_string call_exp); *)
  let method_info, astate =
    let default_info = Option.map ~f:Tenv.MethodInfo.mk_class callee_pname in
    if flags.CallFlags.cf_virtual then
      match get_receiver callee_pname func_args with
      | None ->
          L.internal_error "No receiver on virtual call" ;
          (default_info, astate)
      | Some {ProcnameDispatcher.Call.FuncArg.arg_payload= receiver} -> (
        match
          improve_receiver_static_type astate (ValuePath.value receiver) callee_pname
          |> resolve_virtual_call exe_env tenv astate (ValuePath.value receiver)
        with
        | Some (info, `ExactDevirtualization) ->
            (Some info, astate)
        | Some (info, `ApproxDevirtualization) ->
            (Some info, need_dynamic_type_specialization astate (ValuePath.value receiver))
        | None ->
            (None, astate) )
    else if Language.curr_language_is Hack then
      (* In Hack, a static method can be inherited *)
      let proc_name = Procdesc.get_proc_name proc_desc in
      resolve_hack_static_method path call_loc astate tenv proc_name callee_pname
    else (default_info, astate)
   
  in   
  let callee_pname = Option.map ~f:Tenv.MethodInfo.get_procname method_info in
  let astate, func_args = add_self_for_hack_traits astate method_info func_args in
  
  let astate =
    match (callee_pname, func_args) with
    | Some callee_pname, [{ProcnameDispatcher.Call.FuncArg.arg_payload= arg}]
      when Procname.is_std_move callee_pname ->
        AddressAttributes.add_one (ValuePath.value arg) StdMoved astate
    | _, _ ->
        astate
  in
  let astate =
    List.fold func_args ~init:astate
      ~f:(fun acc {ProcnameDispatcher.Call.FuncArg.arg_payload= arg; exp} ->
        match exp with
        | Cast (typ, _) when Typ.is_rvalue_reference typ ->
            AddressAttributes.add_one (ValuePath.value arg) StdMoved acc
        | _ ->
            acc )
  in     
  let model =
    match callee_pname with
    | Some callee_pname -> (
      match DoliToTextual.matcher callee_pname with
      | Some procname ->
          DoliModel procname
      | None ->
          PulseModels.dispatch tenv callee_pname func_args
          |> Option.value_map ~default:NoModel ~f:(fun model -> OcamlModel (model, callee_pname))
      )
    | None ->
        (* unresolved function pointer, etc.: skip *)
        NoModel
  in
  (* do interprocedural call then destroy objects going out of scope *)
  let _, call_was_unknown =
    match model with
    | OcamlModel (model, callee_procname) ->
      
        L.d_printfln "Found ocaml model for call@\n" ;
        let astate =
          let arg_values =
            List.map func_args ~f:(fun {ProcnameDispatcher.Call.FuncArg.arg_payload= value} ->
                ValuePath.value value )
          in
          PulseOperations.conservatively_initialize_args arg_values astate
        in
        ( model
            { analysis_data
            ; dispatch_call_eval_args
            ; path
            ; callee_procname
            ; location= call_loc
            ; ret }
            astate
        , `KnownCall )
    | DoliModel callee_pname ->
   
        L.d_printfln "Found doli model %a for call@\n" Procname.pp callee_pname ;
        PerfEvent.(log (fun logger -> log_begin_event logger ~name:"pulse interproc call" ())) ;
        let r =
          interprocedural_call analysis_data path ret (Some callee_pname) call_exp func_args
            call_loc flags astate
        in
        PerfEvent.(log (fun logger -> log_end_event logger ())) ;
        r
    | NoModel ->
      (*goes to here*)
        PerfEvent.(log (fun logger -> log_begin_event logger ~name:"pulse interproc call" ())) ;
        let r =
          interprocedural_call analysis_data path ret callee_pname call_exp func_args call_loc
            flags astate
        in
        PerfEvent.(log (fun logger -> log_end_event logger ())) ;
        r
  in
  
  match call_was_unknown with 
  |`KnownCall -> true 
  |`UnknownCall -> false



  let eval_function_call_args path call_exp actuals call_loc astate =
    (* print_endline ("call name "^Exp.to_string call_exp); *)
    
    let** astate, callee_pname = PulseOperations.eval_proc_name path call_loc call_exp astate in
    (* special case for objc dispatch models *)
    let callee_pname, call_exp, actuals =
      match callee_pname with
      | Some callee_pname when ObjCDispatchModels.is_model callee_pname -> 
        (
        match ObjCDispatchModels.get_dispatch_closure_opt actuals with
        | Some (block_name, closure_exp, args) ->
            (Some block_name, closure_exp, args)
        | None ->
            (Some callee_pname, call_exp, actuals) )
      | _ ->
          (callee_pname, call_exp, actuals)
    in
    (* evaluate all actuals *)
    let++ astate, rev_actuals =
      PulseOperationResult.list_fold actuals ~init:(astate, [])
        ~f:(fun (astate, rev_func_args) (actual_exp, actual_typ) ->
          let++ astate, (actual_evaled:ValuePath.t) =
            PulseOperations.eval_to_value_path path Read call_loc actual_exp astate
          in
          (* AbductiveDomain.pp F.std_formatter astate;
          print_endline "====================";
          Exp.pp F.std_formatter actual_exp;
          print_endline "======================="; 
          AbstractValue.pp F.std_formatter (ValuePath.value actual_evaled);
          print_endline ""; *)
          ( astate
          , ProcnameDispatcher.Call.FuncArg.
              {exp= actual_exp; arg_payload= actual_evaled; typ= actual_typ}
            :: rev_func_args ) )
    in
    (* AbductiveDomain.pp F.std_formatter astate; print_endline "intermedia"; *)
    (astate, call_exp, callee_pname, List.rev rev_actuals)


  let dispatch_call analysis_data path ret call_exp actuals call_loc flags astate =
    let<**> astate, call_exp, callee_pname, func_args =
      eval_function_call_args path call_exp actuals call_loc astate
    in
    dispatch_call_eval_args analysis_data path ret call_exp actuals func_args call_loc flags astate
      callee_pname


  (* [get_dealloc_from_dynamic_types vars_types loc] returns a dealloc procname and vars and
     type needed to execute a call to dealloc for the given variables for which the dynamic type
     is an Objective-C class. *)
  let get_dealloc_from_dynamic_types dynamic_types_unreachable =
    let get_dealloc (var, typ) =
      Typ.name typ
      |> Option.bind ~f:(fun name ->
             let cls_typ = Typ.mk (Typ.Tstruct name) in
             match Var.get_ident var with
             | Some id when Typ.is_objc_class cls_typ ->
                 let ret_id = Ident.create_fresh Ident.knormal in
                 let dealloc = Procname.make_objc_dealloc name in
                 let typ = Typ.mk_ptr cls_typ in
                 Some (ret_id, id, typ, dealloc)
             | _ ->
                 None )
    in
    List.filter_map ~f:get_dealloc dynamic_types_unreachable


  (* Count strong references reachable from the stack for each RefCounted
     object in memory and set that count to their respective
     __infer_mode_reference_count field by calling the __objc_set_ref_count
     builtin *)
  let set_ref_counts astate location path
      ({InterproceduralAnalysis.tenv; proc_desc; err_log} as analysis_data) =
    let find_var_opt astate addr =
      Stack.fold
        (fun var (var_addr, _) var_opt ->
          if AbstractValue.equal addr var_addr then Some var else var_opt )
        astate None
    in
    let ref_counts = PulseRefCounting.count_references tenv astate in
    AbstractValue.Map.fold
      (fun addr count (astates, ret_vars) ->
        let ret_vars = ref ret_vars in
        let astates =
          List.concat_map astates ~f:(fun astate ->
              match astate with
              | AbortProgram _
              | ExceptionRaised _
              | ExitProgram _
              | LatentAbortProgram _
              | LatentInvalidAccess _ ->
                  [astate]
              | ContinueProgram astate as default_astate ->
                  let astates : ExecutionDomain.t list option =
                    let open IOption.Let_syntax in
                    let* self_var = find_var_opt astate addr in
                    let+ self_typ, _ =
                      let* attrs = AbductiveDomain.AddressAttributes.find_opt addr astate in
                      Attributes.get_dynamic_type_source_file attrs
                    in
                    let ret_id = Ident.create_fresh Ident.knormal in
                    ret_vars := Var.of_id ret_id :: !ret_vars ;
                    let ret = (ret_id, StdTyp.void) in
                    let call_flags = CallFlags.default in
                    let call_exp = Exp.Const (Cfun BuiltinDecl.__objc_set_ref_count) in
                    let actuals =
                      [ (Var.to_exp self_var, self_typ)
                      ; (Exp.Const (Cint (IntLit.of_int count)), StdTyp.uint) ]
                    in
                    let call_instr = Sil.Call (ret, call_exp, actuals, location, call_flags) in
                    L.d_printfln ~color:Pp.Orange "@\nExecuting injected instr:%a@\n@."
                      (Sil.pp_instr Pp.text ~print_types:true)
                      call_instr ;
                    dispatch_call analysis_data path ret call_exp actuals location call_flags astate
                    |> PulseReport.report_exec_results tenv proc_desc err_log location
                  in
                  Option.value ~default:[default_astate] astates )
        in
        (astates, !ret_vars) )
      ref_counts ([ContinueProgram astate], [])


  (* In the case of variables that point to Objective-C classes for which we have a dynamic type, we
     add and execute calls to dealloc. The main advantage of adding this calls
     is that some memory could be freed in dealloc, and we would be reporting a leak on it if we
     didn't call it. *)
  let execute_injected_dealloc_calls
      ({InterproceduralAnalysis.tenv; proc_desc; err_log} as analysis_data) path vars astate
      location =
    let used_ids = Stack.keys astate |> List.filter_map ~f:(fun var -> Var.get_ident var) in
    Ident.update_name_generator used_ids ;
    let call_dealloc (astate_list : ExecutionDomain.t list) (ret_id, id, typ, dealloc) =
      let ret = (ret_id, StdTyp.void) in
      let call_flags = CallFlags.default in
      let call_exp = Exp.Const (Cfun dealloc) in
      let actuals = [(Exp.Var id, typ)] in
      let call_instr = Sil.Call (ret, call_exp, actuals, location, call_flags) in
      L.d_printfln ~color:Pp.Orange "@\nExecuting injected instr:%a@\n@."
        (Sil.pp_instr Pp.text ~print_types:true)
        call_instr ;
      List.concat_map astate_list ~f:(fun (astate : ExecutionDomain.t) ->
          match astate with
          | AbortProgram _
          | ExceptionRaised _
          | ExitProgram _
          | LatentAbortProgram _
          | LatentInvalidAccess _ ->
              [astate]
          | ContinueProgram astate ->
              dispatch_call analysis_data path ret call_exp actuals location call_flags astate
              |> PulseReport.report_exec_results tenv proc_desc err_log location )
    in
    let dynamic_types_unreachable =
      PulseOperations.get_dynamic_type_unreachable_values vars astate
    in
    let dealloc_data = get_dealloc_from_dynamic_types dynamic_types_unreachable in
    let ret_vars = List.map ~f:(fun (ret_id, _, _, _) -> Var.of_id ret_id) dealloc_data in
    L.d_printfln ~color:Pp.Orange
      "Executing injected call to dealloc for vars (%a) that are exiting the scope@."
      (Pp.seq ~sep:"," Var.pp) vars ;
    let astates = List.fold ~f:call_dealloc dealloc_data ~init:[ContinueProgram astate] in
    (astates, ret_vars)


  let remove_vars vars location astates =
    List.filter_map astates ~f:(fun (exec_state : ExecutionDomain.t) ->
        match exec_state with
        | AbortProgram _ | ExitProgram _ | LatentAbortProgram _ | LatentInvalidAccess _ ->
            Some exec_state
        | ContinueProgram astate -> (
          match PulseOperations.remove_vars vars location astate with
          | Sat astate ->
              Some (ContinueProgram astate)
          | Unsat ->
              None )
        | ExceptionRaised astate -> (
          match PulseOperations.remove_vars vars location astate with
          | Sat astate ->
              Some (ExceptionRaised astate)
          | Unsat ->
              None ) )


  let exit_scope vars location path astate astate_n
      ({InterproceduralAnalysis.proc_desc; tenv} as analysis_data) =
    if Procname.is_java (Procdesc.get_proc_name proc_desc) then
      (remove_vars vars location [ContinueProgram astate], path, astate_n)
    else
      (* Some RefCounted variables must not be removed at their ExitScope
         because they may still be referenced by someone and that reference may
         be destroyed in the future. In that case, we would miss the opportunity
         to properly dealloc the object if it were removed from the stack,
         leading to potential FP memory leaks *)
      let vars = PulseRefCounting.removable_vars tenv astate vars in
      (* Prepare objects in memory before calling any dealloc:
         - set the number of unique strong references accessible from the
          stack to each object's respective __infer_mode_reference_count
          field by calling the __objc_set_ref_count modelled function
         This needs to be done before any call to dealloc because dealloc's
         behavior depends on this ref count and one's dealloc may call
         another's. Consequently, they each need to be up to date beforehand.
         The return variables of the calls to __objc_set_ref_count must be
         removed *)
      let astates, ret_vars = set_ref_counts astate location path analysis_data in
      (* Here we add and execute calls to dealloc for Objective-C objects
         before removing the variables. The return variables of those calls
         must be removed as welll *)
      let astates, ret_vars =
        List.fold_left astates ~init:([], ret_vars)
          ~f:(fun ((acc_astates, acc_ret_vars) as acc) astate ->
            match astate with
            | ContinueProgram astate ->
                let astates, ret_vars =
                  execute_injected_dealloc_calls analysis_data path vars astate location
                in
                (astates @ acc_astates, ret_vars @ acc_ret_vars)
            | _ ->
                acc )
      in
      (* OPTIM: avoid re-allocating [vars] when [ret_vars] is empty
         (in particular if no ObjC objects are involved), but otherwise
         assume [ret_vars] is potentially larger than [vars] and so
         append [vars] to [ret_vars]. *)
      let vars_to_remove = if List.is_empty ret_vars then vars else List.rev_append vars ret_vars in
      ( remove_vars vars_to_remove location astates
      , path
      , PulseNonDisjunctiveOperations.mark_modified_copies_and_parameters vars astates astate_n )


  let and_is_int_if_integer_type typ v astate =
    if Typ.is_int typ then PulseArithmetic.and_is_int v astate else Sat (Ok astate)


  let check_modified_before_dtor args call_exp astate astate_n =
    match ((call_exp : Exp.t), args) with
    | (Const (Cfun proc_name) | Closure {name= proc_name}), (Exp.Lvar pvar, _) :: _
      when Procname.is_destructor proc_name ->
        let var = Var.of_pvar pvar in
        PulseNonDisjunctiveOperations.mark_modified_copies_and_parameters_on_abductive [var] astate
          astate_n
        |> NonDisjDomain.checked_via_dtor var
    | _ ->
        astate_n


  let check_config_usage {InterproceduralAnalysis.proc_desc} loc exp astate =
    let pname = Procdesc.get_proc_name proc_desc in
    let trace = Trace.Immediate {location= loc; history= ValueHistory.epoch} in
    Sequence.fold (Exp.free_vars exp) ~init:(Ok astate) ~f:(fun acc var ->
        Option.value_map (PulseOperations.read_id var astate) ~default:acc ~f:(fun addr_hist ->
            let* acc in
            PulseOperations.check_used_as_branch_cond addr_hist ~pname_using_config:pname
              ~branch_location:loc ~location:loc trace acc ) )


  let set_global_astates path ({InterproceduralAnalysis.proc_desc} as analysis_data) exp typ loc
      astate =
    let is_global_constant pvar =
      Pvar.(is_global pvar && (is_const pvar || is_compile_constant pvar))
    in
    let is_global_func_pointer pvar =
      Pvar.is_global pvar && Typ.is_pointer_to_function typ
      && Config.pulse_inline_global_init_func_pointer
    in
    match (exp : Exp.t) with
    | Lvar pvar when is_global_constant pvar || is_global_func_pointer pvar -> (
      (* Inline initializers of global constants or globals function pointers when they are being used.
         This addresses nullptr false positives by pruning infeasable paths global_var != global_constant_value,
         where global_constant_value is the value of global_var *)
      (* TODO: Initial global constants only once *)
      match Pvar.get_initializer_pname pvar with
      | Some init_pname when not (Procname.equal (Procdesc.get_proc_name proc_desc) init_pname) ->
          L.d_printfln_escaped "Found initializer for %a" (Pvar.pp Pp.text) pvar ;
          let call_flags = CallFlags.default in
          let ret_id_void = (Ident.create_fresh Ident.knormal, StdTyp.void) in
          let no_error_states =
            dispatch_call analysis_data path ret_id_void (Const (Cfun init_pname)) [] loc call_flags
              astate
            |> List.filter_map ~f:(function
                 | Ok (ContinueProgram astate) ->
                     Some astate
                 | _ ->
                     (* ignore errors in global initializers *)
                     None )
          in
          if List.is_empty no_error_states then [astate] else no_error_states
      | _ ->
          [astate] )
    | _ ->
        [astate]
  
  let rec _find_meth tenv proc ty call_exp act_call= 
      let meth_exist = Tenv.method_exsit proc tenv in
      if not meth_exist then 
        let supers = 
        let self = Tenv.lookup tenv ty in 
        match self with | None -> raise Listhd 
                                   | Some stru -> Struct.get_all_supers stru in 
        List.iter supers ~f:(fun super ->
    (* match super with 
    |None -> call_exp
    |Some s-> Typ.print_name s; *)
    (* print_endline "========="; *)
        let p = Procname.Java.replace_class_name super proc in
          _find_meth tenv p super call_exp act_call)
      else act_call := Exp.Const (Cfun (Java proc)) 
  
  let _find_meths tenv proc ty call_exp=
    let act_call = ref Exp.minus_one in 
    let meth_exist = Tenv.method_exsit proc tenv in 
    (* print_endline "=========";
    Typ.print_name ty;
    print_endline "---------------";
    Procname.Java.print_java_proc proc;
    print_endline "---------------";
    Utils.print_bool meth_exist;
    print_endline "--------------"; *)
    if not meth_exist then 
          let supers = 
            let self = Tenv.lookup tenv ty in 
            match self with | None -> raise Listhd 
                                         | Some stru -> Struct.get_all_supers stru in 
          List.iter supers ~f:(fun super ->
          (* match super with 
          |None -> call_exp
          |Some s-> Typ.print_name s; *)
          (* print_endline "========="; *)
            let p = Procname.Java.replace_class_name super proc in
            _find_meth tenv p super call_exp act_call)
    else act_call := Exp.Const (Cfun (Java proc)) ;
    !act_call

  let exec_instr_aux ({PathContext.timestamp} as path) (astate : ExecutionDomain.t)
      (astate_n : NonDisjDomain.t)
      ({InterproceduralAnalysis.tenv; proc_desc; err_log; exe_env} as analysis_data) _cfg_node
      (instr : Sil.instr) : ExecutionDomain.t list * PathContext.t * NonDisjDomain.t =
    match astate with
    | AbortProgram _ | LatentAbortProgram _ | LatentInvalidAccess _ ->
        ([astate], path, astate_n)
    (* an exception has been raised, we skip the other instructions until we enter in
       exception edge *)
    | ExceptionRaised _
    (* program already exited, simply propagate the exited state upwards  *)
    | ExitProgram _ ->
        ([astate], path, astate_n)
    | ContinueProgram astate -> (
      match instr with
      | Load {id= lhs_id; e= rhs_exp; loc; typ} ->
        let () = match rhs_exp with
                  | Const Cclass _ -> Caml.Hashtbl.replace PulseModelsJava.should_analyse_cast (Procdesc.get_proc_name proc_desc) false
                  | _ -> () in
        (* print_endline "=================";
          print_endline ("Load at"^ (Location.to_string loc));
          
          Ident.pp F.std_formatter lhs_id;
          print_endline "////////////////////";
          Exp.pp Format.std_formatter rhs_exp;
          print_endline "================="; *)
          let model_opt = PulseLoadInstrModels.dispatch ~load:rhs_exp in
          let deref_rhs astate =
            (let** astate, rhs_addr_hist =
               match model_opt with
               | None ->
                   (* no model found: evaluate the expression as normal *)
                   PulseOperations.eval_deref path loc rhs_exp astate
               | Some model ->
                   (* we are loading from something modelled; apply the model *)
                   model {path; location= loc} astate
             in
             let rhs_addr, _ = rhs_addr_hist in
             and_is_int_if_integer_type typ rhs_addr astate
             >>|| PulseOperations.hack_propagates_type_on_load tenv path loc rhs_exp rhs_addr
             >>|| PulseOperations.write_id (lhs_id:Ident.t) rhs_addr_hist )
            |> SatUnsat.to_list
            (* |> PulseReport.report_results tenv proc_desc err_log loc *)
          in
          let astates =
            (* call the initializer for certain globals to populate their values, unless we already
               have a model for it *)
            if Option.is_some model_opt then [astate]
            else set_global_astates path analysis_data rhs_exp typ loc astate
          in
          let astate_n =
            match rhs_exp with
            | Lvar pvar ->
                NonDisjDomain.set_load loc timestamp lhs_id (Var.of_pvar pvar) astate_n
            | _ ->
                astate_n
          in
          let res1 = (List.concat_map astates ~f:deref_rhs) in
          let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
          let current_path = (p_path - 1 + (List.length res1)) in 
          Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;
          let res2 = PulseReport.report_results tenv proc_desc err_log loc res1 ~current_disj:current_path ~instra_latent_hash:instr_latent_hash ~ins: (Some instr) in
          let astates, path, non_disj = (res2, path, astate_n) in
          
          let astates =
            let procname = Procdesc.get_proc_name proc_desc in
            List.concat_map astates ~f:(fun astate ->
                match astate with
                | ContinueProgram astate ->
                    let astates =
                      [ PulseTaintOperations.load procname tenv path loc ~lhs:(lhs_id, typ)
                          ~rhs:rhs_exp astate ]
                    in
                    PulseReport.report_results tenv proc_desc err_log loc astates ~current_disj:current_path ~instra_latent_hash:instr_latent_hash ~ins: (Some instr) 
                | _ ->
                    [astate] )
          in
          (astates, path, non_disj)
      | Store {e1= lhs_exp; e2= rhs_exp; loc; typ} ->
          let () = match rhs_exp with
                  | Const Cclass _ -> Caml.Hashtbl.replace PulseModelsJava.should_analyse_cast (Procdesc.get_proc_name proc_desc) false
                  | _ -> ()
          in 
          (* print_endline ("Load at"^ (Location.to_string loc)); *)
          (* [*lhs_exp := rhs_exp] *)
          let event =
            match lhs_exp with
            | Lvar v when Pvar.is_return v ->
                ValueHistory.Returned (loc, timestamp)
            | _ ->
                ValueHistory.Assignment (loc, timestamp)
          in
          let astate_n =
            Exp.program_vars lhs_exp
            |> Sequence.fold ~init:astate_n ~f:(fun astate_n pvar ->
                   NonDisjDomain.set_store loc timestamp pvar astate_n )
          in
          let result =
            let** astate, rhs_value_path =
              PulseOperations.eval_to_value_path path NoAccess loc rhs_exp astate
            in
            let rhs_addr, rhs_history = ValuePath.addr_hist rhs_value_path in
            let** astate, lhs_addr_hist = PulseOperations.eval path Write loc lhs_exp astate in
            let hist = ValueHistory.sequence ~context:path.conditions event rhs_history in
            let** astate = and_is_int_if_integer_type typ rhs_addr astate in
            let=* astate =
              PulseTaintOperations.store tenv path loc ~lhs:lhs_exp
                ~rhs:(rhs_exp, rhs_value_path, typ) astate
            in
            let=+ astate =
              PulseOperations.write_deref path loc ~ref:lhs_addr_hist ~obj:(rhs_addr, hist) astate
            in
            let astate =
              if Topl.is_active () then topl_store_step path loc ~lhs:lhs_exp ~rhs:rhs_exp astate
              else astate
            in
            match lhs_exp with
            | Lvar pvar when Pvar.is_return pvar ->
                PulseOperations.check_address_escape loc proc_desc rhs_addr rhs_history astate
            | _ ->
                Ok astate
          in
          let astate_n = NonDisjDomain.set_captured_variables rhs_exp astate_n in
          let results = SatUnsat.to_list result in
          let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
          let current_path = (p_path - 1 + (List.length results)) in 
          Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;

         
          (PulseReport.report_results tenv proc_desc err_log loc results ~current_disj:current_path ~instra_latent_hash:instr_latent_hash ~ins: (Some instr) , path, astate_n)
      | Call (ret, (call_exp:Exp.t), actuals, loc, (call_flags:CallFlags.t)) ->
        (try
        (* Exp.pp F.std_formatter call_exp; *)
        (match call_exp with 
       
        |Const (Cfun p) when Procname.is_java p
        
        
        ->
          let ty_name = (match Procname.get_class_type_name p with 
                        |None -> raise AboutToOOM
                        |Some n -> n
                        
                        )
          in 
         
          let inter_or_abs_known =  (Tenv.is_java_normal_cls tenv ty_name)  

          in
          let rec helper_check tlist = 
            match tlist with 
            |[] -> false
            |x::xs -> if Tenv.is_java_normal_cls tenv x then true else helper_check xs 

          in
          let inter_or_abs_have_known = if inter_or_abs_known then true
             else helper_check (Tenv.find_limited_sub ty_name tenv)

          in

          let inter_or_abs = Tenv.is_java_abstract_cls tenv ty_name || Tenv.is_java_interface_cls tenv ty_name 

          in
          
          if (String.equal "isAssignableFrom" (Procname.get_method p)) || (String.equal "getType" (Procname.get_method p)) then
            Caml.Hashtbl.replace PulseModelsJava.should_analyse_cast (Procdesc.get_proc_name proc_desc) false;
          let is_known_call = ref true in 
          let is_known_call_aux = eval_function_call_args path call_exp actuals loc astate >>|| fun (astate, call_exp, callee_pname, func_args)
                -> fun_is_known analysis_data path ret call_exp func_args loc
                      call_flags astate callee_pname 
                      in
          let _tryss =  is_known_call_aux >>|| (fun x -> if x then is_known_call := true else is_known_call := false ; x) in
                      
          if (Procname.equal p BuiltinDecl.__new) || (Procname.equal p BuiltinDecl.__cast) 
            ||  ((not (!is_known_call)) && (not inter_or_abs))
            ||  ((not (!is_known_call)) && (not inter_or_abs_have_known) && !AbductiveDomain.server_j)
            ||(List.is_empty actuals) || Procname.is_java_static_method p then

              (*不要做subtyping的情况*)
        
        (* let all_possible_subtypes = 
        in *)
        (* let () = match call_exp with 
       
        |Const (Cfun p) -> if Procname.equal p BuiltinDecl.__new then print_endline "__new"
        |_ -> print_endline "--"
        in *)
         (* CallFlags.pp F.std_formatter call_flags; *)
        (* print_endline "start";
          print_endline ("ret ident "^Ident.to_string (fst ret));
          print_endline ("ret type "^Typ.to_string (snd ret)); *)
          (*actuals -> input arguments and types*)
          (* print_endline (Exp.to_string call_exp) ; *)
          (* list_printer (fun x -> print_endline ("act exp "^Exp.to_string (fst x)); print_endline ("act type " ^Typ.to_string (snd x))) actuals; *)

          let astate_n = check_modified_before_dtor actuals call_exp astate astate_n in
          
          let astates =
            List.fold actuals ~init:[astate] ~f:(fun astates (exp, typ) ->
                List.concat_map astates ~f:(fun astate ->
                    set_global_astates path analysis_data exp typ loc astate ) )
          in
          (* [astates_before] are the states after we evaluate args but before we apply the callee. This is needed for PulseNonDisjunctiveOperations to determine whether we are copying from something pointed to by [this].  *)
          let astates, astates_before =
            let astates_before = ref [] in
            let res =
              List.concat_map astates ~f:(fun astate ->
                  let results_and_before_state =
                    let++ astate, call_exp, callee_pname, func_args =
                      eval_function_call_args path call_exp actuals loc astate
                    in
                    (* stash the intermediate "before" [astate] here because the result monad does
                       not accept more complicated types than lists of states (we need a pair of the
                       before astate and the list of results) *)

                    astates_before := astate :: !astates_before ;
                    (* AbductiveDomain.pp F.std_formatter astate; *)
                    dispatch_call_eval_args analysis_data path ret call_exp actuals func_args loc
                      call_flags astate callee_pname
                  in
                  let<**> r = results_and_before_state in
                  
                  r )
            in
            (* print_endline ((Location.to_string loc)^ "calling location"); *)
            let astates_before = !astates_before in
            let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
            let current_path =  (p_path - 1 + (List.length res)) in 
            Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;
     
            (* Utils.list_printer (fun x -> match PulseResult.fetal_error x with |None -> print_endline "None11" | Some a -> AccessResult.pp a) res; *)
            (PulseReport.report_exec_results tenv proc_desc err_log loc res ~current_path:current_path ~instra_hash:instr_latent_hash ~ins: (Some instr) , astates_before)
          in
           (* Utils.list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; *)
          (* list_printer (fun x -> AbductiveDomain.pp F.std_formatter x) astates_before; (*state before*)
          list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; state after *)
          (* print_endline "here"; *)
          let astate_n, astates =
            let pname = Procdesc.get_proc_name proc_desc in
            let integer_type_widths = Exe_env.get_integer_type_widths exe_env pname in
            PulseNonDisjunctiveOperations.call integer_type_widths tenv proc_desc path loc ~call_exp
              ~actuals ~astates_before astates astate_n
          in
          let astate_n = NonDisjDomain.set_passed_to loc timestamp call_exp actuals astate_n in
          let astate_n =
            List.fold actuals ~init:astate_n ~f:(fun astate_n (exp, _) ->
                NonDisjDomain.set_captured_variables exp astate_n )
          in
          
          (astates, path, astate_n) 
        
        else 

            let act_exp_opt = List.hd actuals in 
            let act_exp = (match  act_exp_opt with
            | Some ac -> ac
            |None -> raise Listhd) in 
            
            let kk =

            PulseOperationResult.sat_ok (PulseOperations.eval_to_value_path path Read loc (fst act_exp) astate)
            (* let kk = match get_receiver (Some) func_args with
            | None -> None
            | Some {ProcnameDispatcher.Call.FuncArg.arg_payload= receiver} -> Some receiver *)
             in 
            let call_obj = 
             (match kk with
            |Some a -> ValuePath.value (snd a)
              
          (* print_endline "====================";
          Exp.pp F.std_formatter (fst act_exp);
          print_endline "======================="; 
          AbstractValue.pp F.std_formatter (ValuePath.value (snd a));
          print_endline ""; *)
            |None -> raise Listhd) in 

          let dynamic_ty = AbductiveDomain.AddressAttributes.get_dynamic_type call_obj astate in 
          (match dynamic_ty with 
            |Some dty ->
              let dy_name = match Typ.name dty with |Some na -> na |None -> raise Listhd in
              let java_p = Procname.as_java_exn ~explanation:"zzz" p in 
              let dy_process = Procname.Java.replace_class_name dy_name java_p in 
              let meth_exist = Tenv.method_exsit dy_process tenv in 
              let call_exp =  if not meth_exist then call_exp else Exp.Const (Cfun (Java dy_process)) in
              (* print_endline "=============="; *)
              
              (* let call_exp = _find_meths tenv dy_process dy_name call_exp in *)

              (* Exp.pp F.std_formatter call_exp; *)
              (* print_endline "=============="; *)
              (* if not meth_exist then Procname.Java.print_java_proc dy_process; *)
              (* let astate = AbductiveDomain.AddressAttributes.remove_static_type_attr *)
              (* AbductiveDomain.pp F.std_formatter astate;
              let astate = AbductiveDomain.AddressAttributes.remove_dynamic_type_attr call_obj astate in
              AbductiveDomain.pp F.std_formatter astate; *)
            let astate_n = check_modified_before_dtor actuals call_exp astate astate_n in
          let astates =
            List.fold actuals ~init:[astate] ~f:(fun astates (exp, typ) ->
                List.concat_map astates ~f:(fun astate ->
                    set_global_astates path analysis_data exp typ loc astate ) )
          in
          (* [astates_before] are the states after we evaluate args but before we apply the callee. This is needed for PulseNonDisjunctiveOperations to determine whether we are copying from something pointed to by [this].  *)
          let astates, astates_before =
            let astates_before = ref [] in
            let res =
              List.concat_map astates ~f:(fun astate ->
                  let results_and_before_state =
                    let++ astate, call_exp, callee_pname, func_args =
                      eval_function_call_args path call_exp actuals loc astate
                    in
                    (* stash the intermediate "before" [astate] here because the result monad does
                       not accept more complicated types than lists of states (we need a pair of the
                       before astate and the list of results) *)

                    astates_before := astate :: !astates_before ;
                    (* AbductiveDomain.pp F.std_formatter astate; *)
                    dispatch_call_eval_args analysis_data path ret call_exp actuals func_args loc
                      call_flags astate callee_pname
                  in
                  let<**> r = results_and_before_state in
                  
                  r )
            in
            (* print_endline ((Location.to_string loc)^ "calling location"); *)
            let astates_before = !astates_before in

            let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
            let current_path = (p_path - 1 + (List.length res))  in 
            Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;

      
            (* Utils.list_printer (fun x -> match PulseResult.fetal_error x with |None -> print_endline "None11" | Some a -> AccessResult.pp a) res; *)
            (PulseReport.report_exec_results tenv proc_desc err_log loc res ~current_path:current_path ~instra_hash:instr_latent_hash ~ins: (Some instr), astates_before)
          in
           (* Utils.list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; *)
          (* list_printer (fun x -> AbductiveDomain.pp F.std_formatter x) astates_before; (*state before*)
          list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; state after *)
          (* print_endline "here"; *)
          let astate_n, astates =
            let pname = Procdesc.get_proc_name proc_desc in
            let integer_type_widths = Exe_env.get_integer_type_widths exe_env pname in
            PulseNonDisjunctiveOperations.call integer_type_widths tenv proc_desc path loc ~call_exp
              ~actuals ~astates_before astates astate_n
          in
          let astate_n = NonDisjDomain.set_passed_to loc timestamp call_exp actuals astate_n in
          let astate_n =
            List.fold actuals ~init:astate_n ~f:(fun astate_n (exp, _) ->
                NonDisjDomain.set_captured_variables exp astate_n )
          in
          
          (astates, path, astate_n)
          |None ->
            let static_ty = AbductiveDomain.AddressAttributes.get_static_type call_obj astate in 
            (match static_ty with
            |Some sty -> let possible_subclass = sty::(Tenv.find_limited_sub sty tenv) in 
            let possible_subclass = List.filter possible_subclass ~f:(fun x -> not (Tenv.is_java_abstract_cls tenv x || Tenv.is_java_interface_cls tenv x)) in
            (* Utils.print_int (List.length possible_subclass); *)
            let astate_n = check_modified_before_dtor actuals call_exp astate astate_n in
            let constrains = Formula.get_all_instance_constrains call_obj astate.path_condition in 
            let yes_instance = Formula.type_list_conversion (fst constrains) in 
            let not_instance = Formula.type_list_conversion (snd constrains) in 
            let possible_subclass_sat = List.fold possible_subclass ~init:[] ~f:(fun acc x -> if Formula.check_dynamic_type_sat x (yes_instance,not_instance) tenv then x::acc else acc ) in

            
            
            let astates_all1, astates_before_all =  List.fold possible_subclass_sat ~init:([],[]) ~f:( fun (ast,astb) cls_name -> 
            
            let call_exp = 
              let java_p = Procname.as_java_exn ~explanation:"zzz" p in 
              let dy_process = Procname.Java.replace_class_name cls_name java_p in 
              (* act_call := call_exp;find_meth tenv dy_process cls_name call_exp;
              !act_call  *)
              (* find_meths tenv dy_process cls_name call_exp  *)
              let meth_exist = Tenv.method_exsit dy_process tenv in 
              if not meth_exist then call_exp else Exp.Const (Cfun (Java dy_process)) 
              (* _find_meths tenv dy_process cls_name call_exp  *)

            in
            let astate = AbductiveDomain.AddressAttributes.add_dynamic_type (Typ.mk_struct cls_name) call_obj astate in
            let astates =
              List.fold actuals ~init:[astate] ~f:(fun astates (exp, typ) ->
                  List.concat_map astates ~f:(fun astate ->
                      set_global_astates path analysis_data exp typ loc astate ) )
            in
            (* [astates_before] are the states after we evaluate args but before we apply the callee. This is needed for PulseNonDisjunctiveOperations to determine whether we are copying from something pointed to by [this].  *)
            let astates, astates_before =
              let astates_before = ref [] in
              let res =
                List.concat_map astates ~f:(fun astate ->
                    let results_and_before_state =
                      let++ astate, call_exp, callee_pname, func_args =
                        eval_function_call_args path call_exp actuals loc astate
                      in
                      (* stash the intermediate "before" [astate] here because the result monad does
                         not accept more complicated types than lists of states (we need a pair of the
                         before astate and the list of results) *)
  
                      astates_before := astate :: !astates_before ;
                      (* AbductiveDomain.pp F.std_formatter astate; *)
                      dispatch_call_eval_args analysis_data path ret call_exp actuals func_args loc
                        call_flags astate callee_pname
                    in
                    let<**> r = results_and_before_state in
                    
                    r )
              in
              (* print_endline ((Location.to_string loc)^ "calling location"); *)
              let astates_before = !astates_before 
              in
              
              (* Utils.list_printer (fun x -> match PulseResult.fetal_error x with |None -> print_endline "None11" | Some a -> AccessResult.pp a) res; *)
              (res, astates_before)
              (* (PulseReport.report_exec_results tenv proc_desc err_log loc res, astates_before) *)
              in (ast@astates,astb@astates_before))
            in

            let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
            let current_path = (p_path - 1 + (List.length astates_all1)) in 
            Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;

         
            let astates_all = PulseReport.report_exec_results tenv proc_desc err_log loc astates_all1 ~current_path:current_path ~instra_hash:instr_latent_hash ~ins: (Some instr) in
             (* Utils.list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; *)
            (* list_printer (fun x -> AbductiveDomain.pp F.std_formatter x) astates_before; (*state before*)
            list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; state after *)
            (* print_endline "here"; *)
            let astate_n, astates =
              let pname = Procdesc.get_proc_name proc_desc in
              let integer_type_widths = Exe_env.get_integer_type_widths exe_env pname in
              PulseNonDisjunctiveOperations.call integer_type_widths tenv proc_desc path loc ~call_exp
                ~actuals ~astates_before:astates_before_all astates_all astate_n
            in
            let astate_n = NonDisjDomain.set_passed_to loc timestamp call_exp actuals astate_n in
            let astate_n =
              List.fold actuals ~init:astate_n ~f:(fun astate_n (exp, _) ->
                  NonDisjDomain.set_captured_variables exp astate_n )
            in
            
            (astates, path, astate_n)
                        

            |None ->
            let astate_n = check_modified_before_dtor actuals call_exp astate astate_n in
            let astates =
              List.fold actuals ~init:[astate] ~f:(fun astates (exp, typ) ->
                  List.concat_map astates ~f:(fun astate ->
                      set_global_astates path analysis_data exp typ loc astate ) )
            in
            (* [astates_before] are the states after we evaluate args but before we apply the callee. This is needed for PulseNonDisjunctiveOperations to determine whether we are copying from something pointed to by [this].  *)
            let astates, astates_before =
              let astates_before = ref [] in
              let res =
                List.concat_map astates ~f:(fun astate ->
                    let results_and_before_state =
                      let++ astate, call_exp, callee_pname, func_args =
                        eval_function_call_args path call_exp actuals loc astate
                      in
                      (* stash the intermediate "before" [astate] here because the result monad does
                         not accept more complicated types than lists of states (we need a pair of the
                         before astate and the list of results) *)
  
                      astates_before := astate :: !astates_before ;
                      (* AbductiveDomain.pp F.std_formatter astate; *)
                      dispatch_call_eval_args analysis_data path ret call_exp actuals func_args loc
                        call_flags astate callee_pname
                    in
                    let<**> r = results_and_before_state in
                    
                    r )
              in
              (* print_endline ((Location.to_string loc)^ "calling location"); *)
              let astates_before = !astates_before in

              let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
              let current_path = (p_path - 1 + (List.length res)) in 
              Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;
         
              (* Utils.list_printer (fun x -> match PulseResult.fetal_error x with |None -> print_endline "None11" | Some a -> AccessResult.pp a) res; *)
              (PulseReport.report_exec_results tenv proc_desc err_log loc res ~current_path:current_path ~instra_hash:instr_latent_hash ~ins: (Some instr), astates_before)
            in
             (* Utils.list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; *)
            (* list_printer (fun x -> AbductiveDomain.pp F.std_formatter x) astates_before; (*state before*)
            list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; state after *)
            (* print_endline "here"; *)
            let astate_n, astates =
              let pname = Procdesc.get_proc_name proc_desc in
              let integer_type_widths = Exe_env.get_integer_type_widths exe_env pname in
              PulseNonDisjunctiveOperations.call integer_type_widths tenv proc_desc path loc ~call_exp
                ~actuals ~astates_before astates astate_n
            in
            let astate_n = NonDisjDomain.set_passed_to loc timestamp call_exp actuals astate_n in
            let astate_n =
              List.fold actuals ~init:astate_n ~f:(fun astate_n (exp, _) ->
                  NonDisjDomain.set_captured_variables exp astate_n )
            in
            
            (astates, path, astate_n)
            )  
          )


          | _ ->  
            (* print_endline "=========";
            Exp.pp F.std_formatter call_exp;
             *)
          let astate_n = check_modified_before_dtor actuals call_exp astate astate_n in
          let astates =
            List.fold actuals ~init:[astate] ~f:(fun astates (exp, typ) ->
                List.concat_map astates ~f:(fun astate ->
                    set_global_astates path analysis_data exp typ loc astate ) )
          in
          (* [astates_before] are the states after we evaluate args but before we apply the callee. This is needed for PulseNonDisjunctiveOperations to determine whether we are copying from something pointed to by [this].  *)
          let astates, astates_before =
            let astates_before = ref [] in
            let res =
              List.concat_map astates ~f:(fun astate ->
                  let results_and_before_state =
                    let++ astate, call_exp, callee_pname, func_args =
                      eval_function_call_args path call_exp actuals loc astate
                    in
                    (* stash the intermediate "before" [astate] here because the result monad does
                       not accept more complicated types than lists of states (we need a pair of the
                       before astate and the list of results) *)

                    astates_before := astate :: !astates_before ;
                    (* AbductiveDomain.pp F.std_formatter astate; *)
                    dispatch_call_eval_args analysis_data path ret call_exp actuals func_args loc
                      call_flags astate callee_pname
                  in
                  let<**> r = results_and_before_state in
                  
                  r )
            in
            (* print_endline ((Location.to_string loc)^ "calling location"); *)
            let astates_before = !astates_before in

            let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
            let current_path =(p_path - 1 + (List.length res)) in 
            Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;


            (* Utils.print_int (List.length res);
            print_endline "========="; *)
            (* Utils.list_printer (fun x -> match PulseResult.fetal_error x with |None -> print_endline "None11" | Some a -> AccessResult.pp a) res; *)
            (PulseReport.report_exec_results tenv proc_desc err_log loc res ~current_path:current_path ~instra_hash:instr_latent_hash ~ins: (Some instr), astates_before)
          in
           (* Utils.list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; *)
          (* list_printer (fun x -> AbductiveDomain.pp F.std_formatter x) astates_before; (*state before*)
          list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; state after *)
          (* print_endline "here"; *)
          let astate_n, astates =
            let pname = Procdesc.get_proc_name proc_desc in
            let integer_type_widths = Exe_env.get_integer_type_widths exe_env pname in
            PulseNonDisjunctiveOperations.call integer_type_widths tenv proc_desc path loc ~call_exp
              ~actuals ~astates_before astates astate_n
          in
          let astate_n = NonDisjDomain.set_passed_to loc timestamp call_exp actuals astate_n in
          let astate_n =
            List.fold actuals ~init:astate_n ~f:(fun astate_n (exp, _) ->
                NonDisjDomain.set_captured_variables exp astate_n )
          in
          
          (astates, path, astate_n)
            
            
            )
        with Listhd -> 
          
          let astate_n = check_modified_before_dtor actuals call_exp astate astate_n in
          let astates =
            List.fold actuals ~init:[astate] ~f:(fun astates (exp, typ) ->
                List.concat_map astates ~f:(fun astate ->
                    set_global_astates path analysis_data exp typ loc astate ) )
          in
          (* [astates_before] are the states after we evaluate args but before we apply the callee. This is needed for PulseNonDisjunctiveOperations to determine whether we are copying from something pointed to by [this].  *)
          let astates, astates_before =
            let astates_before = ref [] in
            let res =
              List.concat_map astates ~f:(fun astate ->
                  let results_and_before_state =
                    let++ astate, call_exp, callee_pname, func_args =
                      eval_function_call_args path call_exp actuals loc astate
                    in
                    (* stash the intermediate "before" [astate] here because the result monad does
                       not accept more complicated types than lists of states (we need a pair of the
                       before astate and the list of results) *)

                    astates_before := astate :: !astates_before ;
                    (* AbductiveDomain.pp F.std_formatter astate; *)
                    dispatch_call_eval_args analysis_data path ret call_exp actuals func_args loc
                      call_flags astate callee_pname
                  in
                  let<**> r = results_and_before_state in
                  
                  r )
            in
            (* print_endline ((Location.to_string loc)^ "calling location"); *)
            let astates_before = !astates_before in

            let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
            let current_path =(p_path - 1 + (List.length res)) in 
            Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;


            (* Utils.print_int (List.length res);
            print_endline "========="; *)
            (* Utils.list_printer (fun x -> match PulseResult.fetal_error x with |None -> print_endline "None11" | Some a -> AccessResult.pp a) res; *)
            (PulseReport.report_exec_results tenv proc_desc err_log loc res ~current_path:current_path ~instra_hash:instr_latent_hash ~ins: (Some instr), astates_before)
          in
           (* Utils.list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; *)
          (* list_printer (fun x -> AbductiveDomain.pp F.std_formatter x) astates_before; (*state before*)
          list_printer (fun x -> ExecutionDomain.pp F.std_formatter x) astates; state after *)
          (* print_endline "here"; *)
          let astate_n, astates =
            let pname = Procdesc.get_proc_name proc_desc in
            let integer_type_widths = Exe_env.get_integer_type_widths exe_env pname in
            PulseNonDisjunctiveOperations.call integer_type_widths tenv proc_desc path loc ~call_exp
              ~actuals ~astates_before astates astate_n
          in
          let astate_n = NonDisjDomain.set_passed_to loc timestamp call_exp actuals astate_n in
          let astate_n =
            List.fold actuals ~init:astate_n ~f:(fun astate_n (exp, _) ->
                NonDisjDomain.set_captured_variables exp astate_n )
          in
          
          (astates, path, astate_n)
          
          
          )


      | Prune (condition, loc, is_then_branch, if_kind) ->
        (* Utils.print_bool is_then_branch; *)
        (* Exp.pp F.std_formatter condition; *)
        (* AbductiveDomain.pp F.std_formatter astate; *)
          let prune_result =
            let=* astate = check_config_usage analysis_data loc condition astate in
              (* AbductiveDomain.pp F.std_formatter astate; *)
            PulseOperations.prune path loc ~(condition:Exp.t) astate
          in
          let path =
            match PulseOperationResult.sat_ok prune_result with
            | None ->
              (* PathContext.pp F.std_formatter path; *)
                path
            | Some (_, hist) ->
                if Sil.is_terminated_if_kind if_kind then
                  let hist =
                    ValueHistory.sequence
                      (ConditionPassed {if_kind; is_then_branch; location= loc; timestamp})
                      hist
                  in
                 
                  {path with conditions= hist :: path.conditions}
                else 
                  (* let () =
                   print_endline "zzzz";
                  PathContext.pp F.std_formatter path;
                  print_endline "zzz" in  *)
                  path
          in
          let results =
            let<++> astate, _ = prune_result in
            (* AbductiveDomain.pp F.std_formatter astate; *)
            astate
          in

          let p_path = Caml.Hashtbl.find current_path_table (Procdesc.get_proc_name proc_desc) in 
          let current_path = if is_then_branch then (p_path + (List.length results)) else (p_path - 1 + (List.length results))  in 
          Caml.Hashtbl.replace current_path_table (Procdesc.get_proc_name proc_desc) current_path;

          (* Utils.print_int current_path; *)
          
        
          (PulseReport.report_exec_results tenv proc_desc err_log loc results ~current_path:current_path ~instra_hash:instr_latent_hash ~ins: (Some instr), path, astate_n)
      | Metadata EndBranches ->
          (* We assume that terminated conditions are well-parenthesised, hence an [EndBranches]
             instruction terminates the most recently seen terminated conditional. The empty case
             shouldn't happen but let's not crash by the fault of possible errors in frontends. *)
          let path = {path with conditions= List.tl path.conditions |> Option.value ~default:[]} in
          ([ContinueProgram astate], path, astate_n)
      | Metadata (ExitScope (vars, location)) ->
          exit_scope vars location path astate astate_n analysis_data
      | Metadata (VariableLifetimeBegins {pvar; typ; loc; is_cpp_structured_binding})
        when not (Pvar.is_global pvar) ->
          ( [ PulseOperations.realloc_pvar tenv path
                ~set_uninitialized:(not is_cpp_structured_binding) pvar typ loc astate
              |> ExecutionDomain.continue ]
          , path
          , astate_n )
      | Metadata
          ( Abstract _
          | CatchEntry _
          | Nullify _
          | Skip
          | TryEntry _
          | TryExit _
          | VariableLifetimeBegins _ ) ->
          ([ContinueProgram astate], path, astate_n) )


  let exec_instr ((astate, path), astate_n) analysis_data cfg_node instr :
      DisjDomain.t list * NonDisjDomain.t =
    let heap_size = heap_size () in
    ( match Config.pulse_max_heap with
    | Some max_heap_size when heap_size > max_heap_size ->
        let pname = Procdesc.get_proc_name analysis_data.InterproceduralAnalysis.proc_desc in
       

        L.internal_error
          "OOM danger: heap size is %d words, more than the specified threshold of %d words. \
           Aborting the analysis of the procedure %a to avoid running out of memory.@\n"
          heap_size max_heap_size Procname.pp pname ;
        (* If we'd not compact, then heap remains big, and we'll keep skipping procedures until
           the runtime decides to compact. *)
        Gc.compact () ;
        raise_notrace AboutToOOM
    | _ ->
        () ) ;
    let astates, path, astate_n =
      exec_instr_aux path astate astate_n analysis_data cfg_node instr
    in
    ( List.map astates ~f:(fun exec_state -> (exec_state, PathContext.post_exec_instr path))
    , astate_n )


  let pp_session_name _node fmt = F.pp_print_string fmt "Pulse"
end

let summary_count_channel =
  lazy
    (let output_dir = Filename.concat Config.results_dir "pulseooil" in
     Unix.mkdir_p output_dir ;
     let filename = Format.asprintf "pulse-summary-count-%a.txt" Pid.pp (Unix.getpid ()) in
     let channel = Filename.concat output_dir filename |> Out_channel.create in
     let close_channel () = Out_channel.close_no_err channel in
     Epilogues.register ~f:close_channel ~description:"close summary_count_channel for Pulse" ;
     channel )


module DisjunctiveAnalyzer =
  AbstractInterpreter.MakeDisjunctive
    (PulseTransferFunctions)
    (struct
      let join_policy = `UnderApproximateAfter Config.pulse_max_disjuncts

      let widen_policy = `UnderApproximateAfterNumIterations Config.pulse_widen_threshold
    end)

let with_html_debug_node node ~desc ~f =
  AnalysisCallbacks.html_debug_new_node_session node
    ~pp_name:(fun fmt -> F.pp_print_string fmt desc)
    ~f


let initial tenv proc_attrs specialization =
  let initial_astate =
    
    AbductiveDomain.mk_initial tenv proc_attrs specialization
    |> PulseSummary.initial_with_positive_self proc_attrs
    |> PulseTaintOperations.taint_initial tenv proc_attrs
  in
  (* AbductiveDomain.pp F.std_formatter initial_astate; *)
  [(ContinueProgram initial_astate, PathContext.initial)]


let should_analyze proc_desc =
  let proc_name = Procdesc.get_proc_name proc_desc in
  let proc_id = Procname.to_unique_id proc_name in
  let f regex = not (Str.string_match regex proc_id 0) in
  Option.value_map Config.pulse_skip_procedures ~f ~default:true
  && not (Procdesc.is_too_big Pulse ~max_cfg_size:Config.pulse_max_cfg_size proc_desc)


let exit_function analysis_data location posts non_disj_astate =
  let astates, astate_n =
    List.fold_left posts ~init:([], non_disj_astate)
      ~f:(fun (acc_astates, astate_n) (exec_state, path) ->
        match exec_state with
        | AbortProgram _
        | ExitProgram _
        | ExceptionRaised _
        | LatentAbortProgram _
        | LatentInvalidAccess _ ->
            (exec_state :: acc_astates, astate_n)
        | ContinueProgram astate ->
            let vars =
              Stack.fold
                (fun var _ vars -> if Var.is_return var then vars else var :: vars)
                astate []
            in
            let astates, _, astate_n =
              PulseTransferFunctions.exit_scope vars location path astate astate_n analysis_data
            in
            (PulseTransferFunctions.remove_vars vars location astates @ acc_astates, astate_n) )
  in
  (List.rev astates, astate_n)


let log_summary_count proc_name summary =
  let counts =
    let summary_kinds = List.map ~f:ExecutionDomain.to_name summary in
    let map =
      let incr_or_one val_opt = match val_opt with Some v -> v + 1 | None -> 1 in
      let update acc s = String.Map.update acc s ~f:incr_or_one in
      List.fold summary_kinds ~init:String.Map.empty ~f:update
    in
    let alist = List.map ~f:(fun (s, i) -> (s, `Int i)) (String.Map.to_alist map) in
    let pname = F.asprintf "%a" Procname.pp_verbose proc_name in
    `Assoc (("procname", `String pname) :: alist)
  in
  Yojson.Basic.to_channel (Lazy.force summary_count_channel) counts ;
  Out_channel.output_char (Lazy.force summary_count_channel) '\n'


  
let analyze specialization
    ({InterproceduralAnalysis.tenv; proc_desc; err_log; exe_env} as analysis_data) =
    (* Procdesc.pp_with_instrs ~print_types:true F.std_formatter proc_desc; *)
    (* Tenv.pp F.std_formatter tenv; print_endline "=========================="; *)
  if should_analyze proc_desc then
    
    let proc_name = Procdesc.get_proc_name proc_desc in
    Caml.Hashtbl.add PulseModelsJava.should_analyse_cast proc_name true;
    let () = match Caml.Hashtbl.find_opt current_path_table proc_name with 
    | None -> Caml.Hashtbl.add current_path_table proc_name 1 
    | _ -> ()

    in 
    let () = match Caml.Hashtbl.find_opt PulseModelsJava.instance_apply_before_abv proc_name with 
    | None -> Caml.Hashtbl.add PulseModelsJava.instance_apply_before_abv proc_name []
    | _ -> ()

    in 
    (* let nodes = Procdesc.get_nodes proc_desc in 
    Utils.unitf_on_list nodes (fun x -> Instrs.pp Pp.text F.std_formatter (Procdesc.Node.get_instrs x)); *)
    (* let () = Procname.process_java_name_iter [proc_name] in *)
    let proc_attrs = Procdesc.get_attributes proc_desc in
    let integer_type_widths = Exe_env.get_integer_type_widths exe_env proc_name in
    let initial =
      (* print_endline "process init";
      Procname.pp_name_only F.std_formatter proc_name; *)
      with_html_debug_node (Procdesc.get_start_node proc_desc) ~desc:"initial state creation"
        ~f:(fun () ->
          let initial_disjuncts = initial tenv proc_attrs specialization in
          (* print_endline "process init end"; *)
          let initial_non_disj =
            PulseNonDisjunctiveOperations.init_const_refable_parameters proc_desc
              integer_type_widths tenv
              (List.map initial_disjuncts ~f:fst)
              NonDisjDomain.bottom
          in
          (* NonDisjDomain.pp F.std_formatter initial_non_disj; *)
          (initial_disjuncts, initial_non_disj) )
    in
    let ((exit_summaries_opt:DisjunctiveAnalyzer.TransferFunctions.Domain.t option), exn_sink_summaries_opt) =
      DisjunctiveAnalyzer.compute_post_including_exceptional analysis_data ~initial proc_desc
    in
    
    (* let procname_java_class = Procname.get_class_name proc_name in *)
     
    
    (* let () =
    (* match procname_java_class with | None -> () 
    | Some aa -> let test_name = "ClasspathOrder" in  
    
  
    if (String.is_suffix ~suffix:test_name aa) then  *)
    let ppp = 
    print_endline "process analysis";
    Procname.pp_name_only F.std_formatter proc_name;
    let res = match exit_summaries_opt with 
    | None  -> ()
    | Some a -> DisjunctiveAnalyzer.TransferFunctions.Domain.pp F.std_formatter a in
    res;print_endline "process analysis end" in ppp
    in *)

    
  
    
  
    (*print_endline "------------------------------------------";
          Utils.print_int !current_path; 
          print_endline "=========================================="; *)
          Caml.Hashtbl.remove current_path_table (Procdesc.get_proc_name proc_desc);
          (* Caml.Hashtbl.reset instr_latent_hash; *)
          (* Caml.Hashtbl.reset LatentIssue.reported_casting; *)
          Caml.Hashtbl.remove PulseModelsJava.instance_apply_before_abv (Procdesc.get_proc_name proc_desc);
    let process_postconditions node posts_opt ~convert_normal_to_exceptional =
      match posts_opt with
      | Some (posts, non_disj_astate) ->
          let node_loc = Procdesc.Node.get_loc node in
          let node_id = Procdesc.Node.get_id node in
          let posts, non_disj_astate =
            (* Do final cleanup at the end of procdesc
               Forget path contexts on the way, we don't propagate them across functions *)
            exit_function analysis_data node_loc posts non_disj_astate
          in
          let posts =
            if convert_normal_to_exceptional then
              List.map posts ~f:(fun edomain ->
                  match edomain with ContinueProgram x -> ExceptionRaised x | _ -> edomain )
            else posts
          in
          let summary = PulseSummary.of_posts tenv proc_desc err_log node_loc posts in
          let is_exit_node =
            Procdesc.Node.equal_id node_id (Procdesc.Node.get_id (Procdesc.get_exit_node proc_desc))
          in
          let summary =
            if is_exit_node then
              let objc_nil_summary = PulseSummary.mk_objc_nil_messaging_summary tenv proc_attrs in
              Option.to_list objc_nil_summary @ summary
            else summary
          in
          (* PulseSummary.pp_pre_post_list F.std_formatter ~pp_kind:(fun _fmt -> ()) summary ; *)
          (* print_endline "------------------------------------------";
          Utils.print_int (List.length summary);
          print_endline "=========================================="; *)
          report_topl_errors proc_desc err_log summary ;
          report_unnecessary_copies proc_desc err_log non_disj_astate ;
          report_unnecessary_parameter_copies tenv proc_desc err_log non_disj_astate ;
          summary
      | None ->
          []
    in
    let report_on_and_return_summaries (summary : ExecutionDomain.summary list) :
        ExecutionDomain.summary list option =
      if Config.trace_topl then
        L.debug Analysis Quiet "ToplTrace: dropped %d disjuncts in %a@\n"
          (PulseTopl.Debug.get_dropped_disjuncts_count ())
          Procname.pp_unique_id
          (Procdesc.get_proc_name proc_desc) ;
      let summary_count = List.length summary in
      if Config.pulse_scuba_logging then
        ScubaLogging.log_count ~label:"pulse_summary" ~value:summary_count ;
      Stats.add_pulse_summaries_count summary_count ;
      if Config.pulse_log_summary_count then log_summary_count proc_name summary ;
      Some summary
    in
    let exn_sink_node_opt = Procdesc.get_exn_sink proc_desc in
    let summaries_at_exn_sink : ExecutionDomain.summary list =
      (* We extract postconditions from the exceptions sink. *)
      match exn_sink_node_opt with
      | Some esink_node ->
          with_html_debug_node esink_node ~desc:"pulse summary creation (for exception sink node)"
            ~f:(fun () ->
              process_postconditions esink_node exn_sink_summaries_opt
                ~convert_normal_to_exceptional:true )
      | None ->
          []
    in
    let exit_node = Procdesc.get_exit_node proc_desc in
    with_html_debug_node exit_node ~desc:"pulse summary creation" ~f:(fun () ->
        let summaries_for_exit =
          process_postconditions exit_node exit_summaries_opt ~convert_normal_to_exceptional:false
        in
        let exit_esink_summaries = summaries_for_exit @ summaries_at_exn_sink in
        report_on_and_return_summaries exit_esink_summaries )
  else None


let checker ?specialization ({InterproceduralAnalysis.proc_desc} as analysis_data) =
  let () =
  let class_name = Procname.get_class_name (Procdesc.get_proc_name proc_desc) 
  in (match class_name with 
      | None -> ()
      | Some a -> if (String.is_suffix a ~suffix:("infer.Lists"))
        then AbductiveDomain.is_list_package := true) ;
      if String.is_substring (Sys.getcwd ()) ~substring:("auth-") then AbductiveDomain.server_j := true ;
      if String.is_substring (Sys.getcwd ()) ~substring:("ssgr") then AbductiveDomain.graph := true
  in 

  (* Procdesc.pp_with_instrs ~print_types:true F.std_formatter proc_desc; *)
  (* Tenv.pp_per_file F.std_formatter (Tenv.FileLocal analysis_data.tenv); *)
  (* print_endline "===================="; *)

  (* let iden = Procdesc.get_access proc_desc in 
  let det = (Procname.to_string ~verbosity:(Procname.Verbose) (Procdesc.get_proc_name proc_desc)) in 
  print_endline ((ProcAttributes.access_to_string iden)^det); *)
  let open IOption.Let_syntax in
  if should_analyze (proc_desc:Procdesc.t) then (
    try
      match specialization with
      | None ->
          let+ pre_post_list = analyze None analysis_data in
          {PulseSummary.main= pre_post_list; specialized= Specialization.Pulse.Map.empty}
      | Some (current_summary, Specialization.Pulse specialization) ->
          let+ pre_post_list = analyze (Some specialization) analysis_data in
          let specialized =
            Specialization.Pulse.Map.add specialization pre_post_list
              current_summary.PulseSummary.specialized
          in
          {current_summary with PulseSummary.specialized}
    with AboutToOOM ->
      (* We trigger GC to avoid skipping the next procedure that will be analyzed. *)
      Gc.major () ;
      None ) 
  else None


let is_already_specialized (Pulse specialization : Specialization.t) (summary : PulseSummary.t) =
  Specialization.Pulse.Map.mem specialization summary.specialized
