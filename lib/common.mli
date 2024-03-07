module Id : sig
  type t

  (** [gen ()] is a new, randomly generated {!Id}. *)
  val gen : unit -> t

  exception Format_error of string

  val to_string : t -> string
  val of_string : string -> t option

  (** [of_string_exn s] is either the {!t} extracted from the string or raises a
      {!Format_error} exception. *)
  val of_string_exn : string -> t

  val compare : t -> t -> int
end

module Timestamp : sig
  type t

  val now : unit -> t
  val to_string : t -> string
  val to_ptime : t -> Ptime.t
  val of_ptime : Ptime.t -> t
end
