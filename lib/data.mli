(** Representation of our chat messages. *)
module Message : sig
  type t

  val make : Common.Id.t -> string -> string -> Common.Timestamp.t -> t

  (** [fresh username content] is 'convenience' constructor that generates a
      random id for the message and uses the current timestamp as its
      timestamp. *)
  val fresh : string -> string -> t

  val id : t -> Common.Id.t

  (** [username message] is the username of the person that posted the
      [message]. *)
  val username : t -> string

  (** [content message] is the content of the [message]. *)
  val content : t -> string

  (** [timestamp message] is the timestamp of when the [message] was posted. *)
  val timestamp : t -> Common.Timestamp.t
end

module User : sig
  type t

  val make : string -> t
  val name : t -> string
end

module Id_map : Map.S with type key = Common.Id.t

module Chat_room : sig
  module type CLIENT = sig
    type t

    val send : string -> t -> unit Lwt.t
  end

  module type S = sig
    type elt
    type t

    val empty : t

    (** [broadcast message chat_room] broadcasts the [message] to every client
        in the [chat_room]. *)
    val broadcast : ?exclude:Common.Id.t list -> string -> t -> unit Lwt.t

    (** [whisper message id chat_room] sends the [message] to only the client with
        [id] in the [chat_room]. *)
    val whisper : string -> Common.Id.t -> t -> unit Lwt.t

    (** [connection id chat_room] returns the connection information ({!elt})
        from the [chat_room] if there is one. *)
    val connection : Common.Id.t -> t -> elt option

    val connect : User.t -> elt -> t -> Common.Id.t
    val disconnect : Common.Id.t -> t -> unit
  end

  module Make (C : CLIENT) : S with type elt = C.t
end
