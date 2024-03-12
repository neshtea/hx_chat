module D = Basic__data

module type REPO = sig
  val save : D.contact -> (unit, string) result Lwt.t
  val list : unit -> (D.contact list, string) result Lwt.t
  val search : string -> (D.contact list, string) result Lwt.t
  val count : unit -> int Lwt.t
end

module Make_repo (Db : Caqti_lwt.CONNECTION) : REPO = struct
  open Caqti_type.Std
  open Caqti_request.Infix

  let rep =
    let encode ({ id; name; address; created_at } : D.contact) =
      Ok
        ( Common.Id.to_string id
        , name
        , address
        , Common.Timestamp.to_ptime created_at )
    in
    let decode (id, name, address, created_at) =
      Ok
        (D.make_contact
           (Common.Id.of_string_exn id)
           name
           address
           (Common.Timestamp.of_ptime created_at))
    in
    custom ~encode ~decode (t4 string string string ptime)
  ;;

  let or_error m =
    Lwt.bind m (function
      | Error err -> Caqti_error.show err |> Lwt.return_error
      | Ok v -> Lwt.return_ok v)
  ;;

  let ( >>= ) = Lwt.bind

  let save contact =
    let query =
      (rep ->. unit)
      @@ "INSERT INTO contacts (id, name, address, created_at) VALUES (?, ?, \
          ?, ?)"
    in
    Db.exec query contact |> or_error
  ;;

  let list_query =
    (unit ->* rep)
    @@ "SELECT id, name, address, created_at FROM contacts ORDER BY created_at"
  ;;

  let list () = Db.collect_list list_query () |> or_error

  let search s =
    let re = Str.regexp_string (String.lowercase_ascii s) in
    let is_substring re s =
      try
        ignore (Str.search_forward re (String.lowercase_ascii s) 0);
        true
      with
      | Not_found -> false
    in
    let filter =
      List.filter (fun ({ name; address; _ } : D.contact) ->
        is_substring re name || is_substring re address)
    in
    Db.collect_list
      list_query
      () (* NOTE (Marco): sorry, I couldn't get a LIKE query to work. *)
    >>= (function
           | Error err -> Lwt.return_error err
           | Ok contacts -> filter contacts |> Lwt.return_ok)
    |> or_error
  ;;

  let count () =
    let query = (unit ->? int) @@ "SELECT count(*) FROM contacts" in
    Db.find_opt query ()
    >>= function
    | Error _ | Ok None -> Lwt.return 0
    | Ok (Some cnt) -> Lwt.return cnt
  ;;
end
