type error = string
type 'a repo_result = ('a, error) result Lwt.t

module Message : sig
  module type S = sig
    val read_all : unit -> Data.Message.t list repo_result
    val post : string -> string -> Data.Message.t repo_result
    val count : unit -> int Lwt.t
  end

  module Caqti_lwt (_ : Caqti_lwt.CONNECTION) : S
end
