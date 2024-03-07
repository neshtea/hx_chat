module Id = struct
  type t = Uuidm.t

  let gen () = Uuidm.v `V4
  let to_string t = Uuidm.to_string t
  let of_string t = Uuidm.of_string t

  exception Format_error of string

  let of_string_exn s =
    match of_string s with
    | None -> raise (Format_error s)
    | Some t -> t
  ;;

  let compare = Uuidm.compare
end

module Timestamp = struct
  type t = Ptime.t

  let now () = Ptime_clock.now ()
  let to_string t = Ptime.to_rfc3339 t
  let to_ptime t = t
  let of_ptime ptime = ptime
end
