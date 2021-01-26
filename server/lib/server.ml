open Lwt.Infix

module Make (Backend : Backend_intf.S) = struct
  let serv_text ~content_type body =
    let headers = Cohttp.Header.init_with "Content-Type" content_type in
    Cohttp_lwt_unix.Server.respond_string ~headers ~status:`OK ~body ()

  let option_to_string = function
    | None -> ""
    | Some s -> s

  let get_query_param_list uri name =
    Uri.query uri |>
    List.fold_left begin fun acc (k, v) ->
      if String.equal k name then v @ acc else acc
    end [] |>
    List.rev

  let parse_raw_query logdir uri =
    let checkbox_default def = if List.is_empty (Uri.query uri) then def else false in
    let compilers = get_query_param_list uri "comp" in
    let show_available = get_query_param_list uri "available" in
    let show_failures_only = option_to_string (Uri.get_query_param uri "show-failures-only") in
    let show_failures_only = if String.is_empty show_failures_only then checkbox_default false else bool_of_string show_failures_only in
    let show_diff_only = option_to_string (Uri.get_query_param uri "show-diff-only") in
    let show_diff_only = if String.is_empty show_diff_only then checkbox_default false else bool_of_string show_diff_only in
    let show_latest_only = option_to_string (Uri.get_query_param uri "show-latest-only") in
    let show_latest_only = if String.is_empty show_latest_only then checkbox_default true else bool_of_string show_latest_only in
    let sort_by_revdeps = option_to_string (Uri.get_query_param uri "sort-by-revdeps") in
    let sort_by_revdeps = if String.is_empty sort_by_revdeps then checkbox_default false else bool_of_string sort_by_revdeps in
    let maintainers = option_to_string (Uri.get_query_param uri "maintainers") in
    let maintainers = if String.is_empty maintainers then None else Some maintainers in
    let maintainers = (option_to_string maintainers, Option.map (Re.Posix.compile_pat ~opts:[`ICase]) maintainers) in
    let logsearch = option_to_string (Uri.get_query_param uri "logsearch") in
    let logsearch = if String.is_empty logsearch then None else Some logsearch in
    let logsearch' =
      Option.map2 begin fun re comp ->
        (Re.Posix.compile_pat ~opts:[`Newline] re, Intf.Compiler.from_string comp)
      end logsearch (Uri.get_query_param uri "logsearch_comp")
    in
    let logsearch = (option_to_string logsearch, logsearch') in
    Cache.get_compilers ~logdir Backend.cache >>= fun available_compilers ->
    let compilers = match compilers with
      | [] -> available_compilers
      | compilers -> List.map Intf.Compiler.from_string compilers
    in
    let show_available = match show_available with
      | [] -> compilers
      | show_available -> List.map Intf.Compiler.from_string show_available
    in
    Lwt.return {
      Html.available_compilers;
      Html.compilers;
      Html.show_available;
      Html.show_failures_only;
      Html.show_diff_only;
      Html.show_latest_only;
      Html.sort_by_revdeps;
      Html.maintainers;
      Html.logsearch;
    }

  let filter_path path =
    let path = List.filter (fun file -> not (String.is_empty file)) path in
    if not (List.for_all Oca_lib.is_valid_filename path) then
      failwith "Forbidden path";
    path

  let path_from_uri uri =
    match Uri.path uri with
    | "" -> []
    | path -> filter_path (Fpath.segs (Fpath.v path))

  let callback workdir backend _conn req _body =
    let uri = Cohttp.Request.uri req in
    let get_log ~logdir ~comp ~state ~pkg =
      let logdir = Server_workdirs.logdir_from_string workdir logdir in
      let comp = Intf.Compiler.from_string comp in
      let state = Intf.State.from_string state in
      Backend.get_log backend ~logdir ~comp ~state ~pkg >>= fun log ->
      serv_text ~content_type:"text/plain; charset=utf-8" log
    in
    match path_from_uri uri with
    | [] ->
        print_endline "Looking up cacge directory";
        Cache.get_latest_logdir Backend.cache >>= fun logdir ->
        print_endline "Got past logdir";
        parse_raw_query logdir uri >>= fun query ->
        Cache.get_html Backend.cache query logdir >>= fun html ->
        serv_text ~content_type:"text/html" html
    | ["run"] ->
        Cache.get_html_run_list Backend.cache >>= fun html ->
        serv_text ~content_type:"text/html" html
    | ["run";logdir] ->
        let logdir = Server_workdirs.logdir_from_string workdir logdir in
        parse_raw_query logdir uri >>= fun query ->
        Cache.get_html Backend.cache query logdir >>= fun html ->
        serv_text ~content_type:"text/html" html
    | ["diff"] ->
        Cache.get_html_diff_list Backend.cache >>=
        serv_text ~content_type:"text/html"
    | ["diff"; range] ->
        let (old_logdir, new_logdir) = match String.split_on_char '.' range with
          | [old_logdir; ""; new_logdir] -> (old_logdir, new_logdir)
          | _ -> assert false
        in
        let old_logdir = Server_workdirs.logdir_from_string workdir old_logdir in
        let new_logdir = Server_workdirs.logdir_from_string workdir new_logdir in
        Cache.get_html_diff ~old_logdir ~new_logdir Backend.cache >>= fun html ->
        serv_text ~content_type:"text/html" html
    | ["log"; logdir; comp; state; pkg] ->
        get_log ~logdir ~comp ~state ~pkg
    | _ ->
        failwith "path non recognized: 404"

  let tcp_server ~debug port callback =
    Printexc.record_backtrace debug;
    Cohttp_lwt_unix.Server.create
      ~on_exn:(fun e -> if debug then prerr_endline Printexc.(get_backtrace () ^ to_string e))
      ~mode:(`TCP (`Port port))
      (Cohttp_lwt_unix.Server.make ~callback ())

  let main ~debug ~workdir ~build =
    print_endline (string_of_bool debug);
    let workdir = Server_workdirs.create ~workdir in
    Server_workdirs.init_base workdir >>= fun () ->
    let conf = Server_configfile.from_workdir workdir in
    let port = Server_configfile.port conf in
    Backend.start build conf workdir >>= fun (backend, backend_task) ->
    Lwt.join [
      tcp_server ~debug port (callback workdir backend);
      backend_task ();
    ]
end
