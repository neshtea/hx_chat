type error = string
type 'a repo_result = ('a, error) result Lwt.t

module Message = struct
  module Id = Common.Id
  module Timestamp = Common.Timestamp
  module Message = Data.Message

  module type S = sig
    val read_all : unit -> Message.t list repo_result
    val post : string -> string -> Message.t repo_result
    val count : unit -> int Lwt.t
  end

  module Caqti_lwt (Db : Caqti_lwt.CONNECTION) : S = struct
    open Caqti_request.Infix
    open Caqti_type.Std

    let db_message =
      let encode message =
        Ok
          ( Message.id message |> Id.to_string
          , Message.username message
          , Message.content message
          , Message.timestamp message |> Timestamp.to_ptime )
      in
      let decode (id, username, content, timestamp) =
        Message.make
          (Id.of_string_exn id)
          username
          content
          (Timestamp.of_ptime timestamp)
        |> Result.ok
      in
      custom ~encode ~decode (tup4 string string string ptime)
    ;;

    let or_error m =
      let ( >>= ) = Lwt.bind in
      m
      >>= function
      | Error err -> Caqti_error.show err |> Lwt.return_error
      | Ok result -> Lwt.return_ok result
    ;;

    let read_all () =
      let query =
        (unit ->* db_message)
        @@ "SELECT id, username, content, timestamp FROM messages ORDER BY \
            timestamp DESC"
      in
      Db.collect_list query () |> or_error
    ;;

    let post username content =
      let query =
        (db_message ->. unit)
        @@ "INSERT INTO messages (id, username, content, timestamp) VALUES (?, \
            ?, ?, ?)"
      in
      let message = Message.fresh username content in
      Lwt.bind (Db.exec query message) (function
        | Error err -> Caqti_error.show err |> Lwt.return_error
        | Ok () -> Lwt.return_ok message)
    ;;

    let count () =
      let query = (unit ->? int) @@ "SELECT count(*) FROM messages" in
      Lwt.bind (Db.find_opt query ()) (function
        | Error _ -> Lwt.return 0
        | Ok (Some i) -> Lwt.return i
        | Ok None -> Lwt.return 0)
    ;;
  end
end
