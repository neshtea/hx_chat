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

module Middleware = struct
  (* Middleware to handle errors *)
  (* SEE https://github.com/yawaramin/dream-html/blob/8a0c62e9885421e7e84c6cfc374d06ec6bee98d0/app/app.ml#L15 *)
  let dreamcatcher next req =
    Lwt.catch
      (fun () -> next req)
      (fun exn ->
        let status, msg =
          match exn with
          | Not_found -> `Not_Found, "not found"
          | Failure msg | Assert_failure (msg, _, _) -> `Bad_Request, msg
          | Invalid_argument msg -> `Status 422, msg
          | _ -> `Internal_Server_Error, "something went wrong"
        in
        Dream.error (fun log -> log "%s" @@ Printexc.to_string exn);
        Dream.respond ~status msg)
  ;;
end

module Http = struct
  let internal_server_error msg = Dream.html ~status:`Internal_Server_Error msg
end
