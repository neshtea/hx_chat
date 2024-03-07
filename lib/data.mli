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

module Id_map : Map.S with type key = Common.Id.t

module Chat_room : sig
  type t

  val make : Dream.websocket Id_map.t -> t
  val empty : t
  val connections : t -> Dream.websocket Id_map.t
  val broadcast : string -> t -> unit Lwt.t
  val connect : Dream.websocket -> t -> Common.Id.t
  val disconnect : Common.Id.t -> t -> unit
end
