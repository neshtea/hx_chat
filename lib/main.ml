module Id = Common.Id
module Timestamp = Common.Timestamp
module Message = Data.Message
module Http = Common.Http

let ( let* ) = Lwt.bind
let is_hx_request req = Dream.header req "HX-Request" |> Option.is_some

let get_message_repo req =
  Dream.sql req (fun (module Db) ->
    let module R = Repo.Message.Caqti_lwt (Db) in
    Lwt.return (module R : Repo.Message.S))
;;

let handle_index req = Template.Page.login req |> Dream_html.respond

module Ws = struct
  module Impl = Data.Chat_room.Make (struct
      type t = Dream.websocket

      let send message websocket = Dream.send websocket message
    end)

  let chat_room = ref Impl.empty

  let broadcast ?(exclude = []) message =
    Impl.broadcast ~exclude (message |> Dream_html.to_string) !chat_room
  ;;

  let broadcast_message message count =
    Template.broadcasted_message message count |> broadcast
  ;;

  let connect username websocket =
    Impl.connect (Data.User.make username) websocket !chat_room
  ;;

  let disconnect client_id = Impl.disconnect client_id !chat_room

  let notify ~origin message =
    Template.notification message |> broadcast ~exclude:[ origin ]
  ;;
end

let handle_get_chatroom req =
  let* m = get_message_repo req in
  let module Message_repo = (val m) in
  match Dream.query req "username" with
  | None -> failwith "missing username"
  | Some username ->
    Dream.websocket (fun websocket ->
      let client_id = Ws.connect username websocket in
      let* () =
        Printf.sprintf "%s loggin in" username |> Ws.notify ~origin:client_id
      in
      let rec loop () =
        let* received = Dream.receive websocket in
        match received with
        | None ->
          Dream.log "none -- closing websocket%!";
          let* () =
            Printf.sprintf "%s logged off" username
            |> Ws.notify ~origin:client_id
          in
          Ws.disconnect client_id;
          Dream.close_websocket websocket
        | Some json_string ->
          (match Yojson.Safe.from_string json_string with
           | `Assoc [ ("content", `String content); ("HEADERS", _) ] ->
             let* message_promise = Message_repo.post username content in
             (match message_promise with
              | Error err -> failwith err
              | Ok message ->
                let* count = Message_repo.count () in
                let* () = Ws.broadcast_message message count in
                loop ())
           | _ -> loop ())
      in
      loop ())
;;

let handle_get_count req =
  let* m = get_message_repo req in
  let module Message_repo = (val m) in
  let* count = Message_repo.count () in
  Template.message_count count |> Dream_html.respond
;;

let handle_post_login req =
  let* form = Dream.form req in
  match form with
  | `Ok [ ("username", username) ] ->
    Dream.redirect req (Printf.sprintf "/chat?username=%s" username)
  | _ -> Dream.redirect req "/"
;;

let handle_get_chat req =
  match Dream.query req "username" with
  | None -> Dream.redirect req "/"
  | Some username ->
    let* m = get_message_repo req in
    let module Message_repo = (val m) in
    let* messages = Message_repo.read_all () in
    (match messages with
     | Error err -> Http.internal_server_error err
     | Ok messages ->
       Template.Page.chat_app username messages |> Dream_html.respond)
;;

let routes =
  [ Dream.get "/" handle_index
  ; Dream.get "/chatroom" handle_get_chatroom
  ; Dream.get "/count" handle_get_count
  ; Dream.post "/login" handle_post_login
  ; Dream.get "/chat" handle_get_chat
  ]
;;

let main db_file =
  Dream.run
  @@ Dream.sql_pool (Printf.sprintf "sqlite3:%s?create=true&write=true" db_file)
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Common.Middleware.dreamcatcher
  @@ Dream.router routes
;;
