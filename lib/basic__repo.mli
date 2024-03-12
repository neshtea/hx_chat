module type REPO = sig
  val save : Basic__data.contact -> (unit, string) result Lwt.t
  val list : unit -> (Basic__data.contact list, string) result Lwt.t
  val search : string -> (Basic__data.contact list, string) result Lwt.t
  val count : unit -> int Lwt.t
end

module Make_repo (_ : Caqti_lwt.CONNECTION) : REPO
