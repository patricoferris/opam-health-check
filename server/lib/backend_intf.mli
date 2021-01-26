type task = unit -> unit Lwt.t

module type S = sig
  type t

  type build
  
  val build_of_string : string -> build

  val build_to_string : build -> string

  val cache : Cache.t

  val get_log : t -> logdir:Server_workdirs.logdir -> comp:Intf.Compiler.t -> state:Intf.State.t -> pkg:string -> string Lwt.t

  val start : build -> Server_configfile.t -> Server_workdirs.t -> (t * task) Lwt.t
end
