(* a very basic little chat app in ocaml and htmx *)

module Id = Common.Id
module Timestamp = Common.Timestamp
module Message = Data.Message

module Template = struct
  module H = Dream_html
  module Hh = H.HTML
  module Hx = H.Hx

  (* render a single message *)
  let render_message ?(swap_oob = false) message =
    let base =
      Hh.span
        []
        [ H.txt "%s: %s" (Message.username message) (Message.content message) ]
    in
    if swap_oob
    then Hh.div [ Hx.swap_oob "beforeend:#message-list" ] [ Hh.li [] [ base ] ]
    else base
  ;;

  let message_count ?(swap_oob = false) cnt =
    Hh.span
      ([ Hh.id "message-count"; Hx.swap_oob "%b" swap_oob ]
       @
       if swap_oob
       then []
       else
         (* The first oob swap will get rid of the polling. Could be nicer, I
            guess. *)
         [ Hx.get "/count"
         ; Hx.trigger "load delay:500ms"
         ; Hx.swap "outerHTML"
         ; Hx.target "body"
         ])
      [ H.txt "%i" cnt ]
  ;;

  let return x = [ x ]

  (* render a list of messages. *)
  let render_messages messages =
    let message_list =
      messages
      |> List.map (fun message -> Hh.li [] [ render_message message ])
      |> Hh.ul [ Hh.id "message-list"; Hh.class_ "list-unstyled" ]
      |> return
      |> Hh.div
           [ Hh.class_ "card-body overflow-auto"
           ; Hh.style_ "height: 480px; flex-direction: column-reverse"
           ]
      |> return
      |> Hh.div [ Hh.class_ "card" ]
    in
    Hh.div [] [ message_list ]
  ;;

  let message_input =
    Hh.div
      [ Hh.class_ "fixed-bottom" ]
      [ Hh.form
          [ Hx.ws_send; Hx.on_ ~event:":after-submit" "this.reset()" ]
          [ Hh.div
              [ Hh.class_ "input-group" ]
              [ Hh.input
                  [ Hh.type_ "text"
                  ; Hh.placeholder "Username"
                  ; Hh.name "username"
                  ; Hh.class_ "form-control"
                  ]
              ; Hh.input
                  [ Hh.type_ "text"
                  ; Hh.placeholder "your message here"
                  ; Hh.name "content"
                  ; Hh.class_ "form-control"
                  ]
              ; Hh.button
                  [ Hh.type_ "submit"; Hh.class_ "btn btn-small btn-info" ]
                  [ H.txt "post!" ]
              ]
          ]
      ]
  ;;

  let chatroom =
    Hh.div [ Hx.ws_connect "/chatroom"; Hx.ext "ws" ] [ message_input ]
  ;;

  let nav msg_cnt =
    Hh.nav
      [ Hh.class_ "navbar sticky-top" ]
      [ Hh.div
          [ Hh.class_ "container-fluid" ]
          [ Hh.a [ Hh.class_ "navbar-brand" ] [ H.txt "BOB Chat" ]
          ; H.txt "Number of messages: "
          ; message_count msg_cnt
          ]
      ]
  ;;

  let base content =
    Hh.html
      []
      [ Hh.header
          []
          [ Hh.link
              [ Hh.rel "stylesheet"
              ; Hh.href
                  "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css"
              ; Hh.integrity
                  "sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN"
              ; Hh.crossorigin `anonymous
              ]
          ]
      ; Hh.body
          []
          [ Hh.div
              [ Hh.class_ "container-fluid" ]
              ([ Hh.script [ Hh.src "https://unpkg.com/htmx.org@1.9.10" ] ""
               ; Hh.script
                   [ Hh.src "https://unpkg.com/htmx.org/dist/ext/ws.js" ]
                   ""
               ; nav 0
               ]
               @ content
               @ [ chatroom ])
          ]
      ]
  ;;
end

let ( let* ) = Lwt.bind
let is_hx_request req = Dream.header req "HX-Request" |> Option.is_some

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

let get_message_repo req =
  Dream.sql req (fun (module Db) ->
    let module R = Repo.Message.Caqti_lwt (Db) in
    Lwt.return (module R : Repo.Message.S))
;;

let bad_request msg =
  Dream.html
    ~status:`Bad_Request (* NOTE maybe this should be 422 instead of 400. *)
    msg
;;

let internal_server_error msg = Dream.html ~status:`Internal_Server_Error msg

let handle_index req =
  let* m = get_message_repo req in
  let module Message_repo = (val m) in
  let* messages = Message_repo.read_all () in
  match messages with
  | Ok messages ->
    (* [ Template.message_form req; *)
    [ Template.render_messages messages ] |> Template.base |> Dream_html.respond
  | Error err -> internal_server_error err
;;

let chat_room = ref Data.Chat_room.empty

let broadcast message count =
  Data.Chat_room.broadcast
    (Dream_html.HTML.null
       [ Template.render_message ~swap_oob:true message
       ; Template.message_count ~swap_oob:true count
       ]
     |> Dream_html.to_string)
    !chat_room
;;

let connect websocket = Data.Chat_room.connect websocket !chat_room
let disconnect client_id = Data.Chat_room.disconnect client_id !chat_room

let handle_post_message req =
  let* form = Dream.form req in
  match form with
  | `Ok [ ("content", content); ("username", username) ] ->
    let* m = get_message_repo req in
    let module Message_repo = (val m) in
    let* res = Message_repo.post username content in
    (match res with
     | Error err -> internal_server_error err
     | Ok message ->
       if is_hx_request req
       then
         let* count = Message_repo.count () in
         Dream_html.HTML.null
           [ Dream_html.HTML.div [] [ Template.render_message message ]
           ; Template.message_count ~swap_oob:true count
           ]
         |> Dream_html.respond
       else Dream.redirect req "/")
  | _ -> bad_request "something is missing"
;;

let handle_get_chatroom req =
  let* m = get_message_repo req in
  let module Message_repo = (val m) in
  Dream.websocket (fun websocket ->
    let client_id = connect websocket in
    let rec loop () =
      let* received = Dream.receive websocket in
      match received with
      | None ->
        Dream.log "none -- closing websocket%!";
        disconnect client_id;
        Dream.close_websocket websocket
      | Some json_string ->
        (match Yojson.Safe.from_string json_string with
         | `Assoc
             [ ("username", `String username)
             ; ("content", `String content)
             ; ("HEADERS", _)
             ] ->
           let* message_promise = Message_repo.post username content in
           (match message_promise with
            | Error err -> failwith err
            | Ok message ->
              let* count = Message_repo.count () in
              let* () = broadcast message count in
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

let routes =
  [ Dream.get "/" handle_index
  ; Dream.post "/message" handle_post_message
  ; Dream.get "/chatroom" handle_get_chatroom
  ; Dream.get "/count" handle_get_count
  ]
;;

let main () =
  Dream.run
  @@ Dream.sql_pool "sqlite3:db.sqlite?create=true&write=true"
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ dreamcatcher
  @@ Dream.router routes
;;
