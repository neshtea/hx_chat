type error = string
type 'a repo_result = ('a, error) result Lwt.t

module Message : sig
  module type S = sig
    (** [read_all ()] is the list of all messages in the repository. *)
    val read_all : unit -> Data.Message.t list repo_result

    (** [post username message] posts a new message to the repository. Returns
        the generated {!Data.Message.t}. *)
    val post : string -> string -> Data.Message.t repo_result

    (** [count ()] is the current number of messages in the repository. Always
        returns a number. If anything goes wrong, defaults to [0] as its
        result. *)
    val count : unit -> int Lwt.t
  end

  (** Functor that provides an implementation of the Repository {!S}, using a
      relational database. Based on a {!Caqti_lwt.CONNECTION}. *)
  module Caqti_lwt (_ : Caqti_lwt.CONNECTION) : S
end
