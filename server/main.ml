module Server = Oca_server.Server.Make (Backend)

let main debug workdir build = Lwt_main.run (Server.main ~debug ~workdir ~build)

let build = 
  let builder = 
    let parser = 
      Cmdliner.Arg.parser_of_kind_of_string 
      ~kind:"Build type -- macos or defaults to linux" 
      (fun s -> Some (Backend.build_of_string s))
    in 
    let print ppf p = Format.fprintf ppf "%s" (Backend.build_to_string p) in 
    Cmdliner.Arg.conv (parser, print)
  in
  let doc = "The build type for Obuilder jobs -- for testing purposes only. It can be one of Linux or MacOS." in 
  Cmdliner.Arg.(value & opt builder (Backend.build_of_string "linux") & info ~doc ~docv:"BUILD" ["build"; "b"])


let term =
  let ($) = Cmdliner.Term.($) in
  Cmdliner.Term.pure main $
  Cmdliner.Arg.(value & flag & info ["debug"]) $ 
  Cmdliner.Arg.(required & pos 0 (some string) None & info ~docv:"WORKDIR" []) $ 
  build

let info =
  Cmdliner.Term.info
    ~doc:"A server to check for broken opam packages."
    ~man:[`P "This program takes a work directory where every files created \
              are stored. This includes logs, config file and user private \
              keys."]
    ~version:Config.version
    Config.name

let () = Cmdliner.Term.exit (Cmdliner.Term.eval (term, info))
