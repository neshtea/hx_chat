(** {1 Common utilities} *)

(** Generating, showing and parsing uuids. *)
module Id : sig
  type t

  (** [gen ()] is a new, randomly generated {!Id}. *)
  val gen : unit -> t

  exception Format_error of string

  (** [to_string id] is the string representation of the [id]. *)
  val to_string : t -> string

  (** [of_string s] is the id represented by [s]. *)
  val of_string : string -> t option

  (** [of_string s] is the id represented by [s].

      @raise {!Format_error}
        when [s] is not a proper string representation of
        an id. *)
  val of_string_exn : string -> t

  val compare : t -> t -> int
end

(** Generating, showing and parsing utc-timestamps. *)
module Timestamp : sig
  type t

  (** [now ()] returns the timestamp of the current utc-time. *)
  val now : unit -> t

  (** [to_string timestamp] is the string representation of the [timestamp]. *)
  val to_string : t -> string

  (** [to_ptime timestamp] is the exact timestamp, represented as a
      {!Ptime.t}. *)
  val to_ptime : t -> Ptime.t

  (** [of_ptime ptime] is the exact ptime, represented as a {!t}. *)
  val of_ptime : Ptime.t -> t
end

(** Custom middleware for the webserver. *)
module Middleware : sig
  (** [dreamcatcher handler] catches any exceptions that are raised in the
      handler but not caught anywhere else and tries to respond with an
      appropriate http-response. *)
  val dreamcatcher : ('a -> Dream.response Lwt.t) -> 'a -> Dream.response Lwt.t
end

module Http : sig
  val internal_server_error : string -> Dream.response Lwt.t
end
