module Id = Common.Id
module Timestamp = Common.Timestamp
module Message = Data.Message
module H = Dream_html
module Hh = H.HTML
module Hx = H.Hx

type html = H.node

(* render a single message *)
let render_message ?(swap_oob = false) message =
  let base =
    Hh.span
      []
      [ H.txt "%s: %s" (Message.username message) (Message.content message) ]
  in
  if swap_oob
  then Hh.div [ Hx.swap_oob "beforeend:#message-list" ] [ Hh.p [] [ base ] ]
  else base
;;

let message_count ?(swap_oob = false) cnt =
  if swap_oob
  then Hh.span [] [ H.txt "%i" cnt ]
  else Hh.span [] [ H.txt "%i" cnt ]
;;

let return x = [ x ]

(* render a list of messages. *)
let render_messages messages =
  let message_list =
    messages
    |> List.map (fun message -> Hh.p [] [ render_message message ])
    |> Hh.div [ Hh.id "message-list"; Hh.class_ "list-unstyled" ]
    |> return
    |> Hh.div
         [ Hh.class_ "card-body overflow-auto"
         ; Hh.style_
             (* make sure the bottom of the chat will be in focus until the user scrolls up. *)
             "height: 480px; display: flex; flex-direction: column-reverse"
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
        [ Hx.ws_send ]
        [ Hh.div
            [ Hh.class_ "input-group" ]
            [ Hh.input
                [ Hh.type_ "text"
                ; Hh.placeholder "your message here"
                ; Hh.name "content"
                ; Hh.class_ "form-control"
                ; Hh.autofocus
                ]
            ; Hh.button
                [ Hh.type_ "submit"; Hh.class_ "btn btn-small btn-info" ]
                [ H.txt "post!" ]
            ]
        ]
    ]
;;

let notifications =
  Hh.div
    []
    [ Hh.h5 [] [ H.txt "Notifications" ]
    ; Hh.ul [ Hh.id "notifications"; Hh.class_ "list-unstyled" ] []
    ]
;;

let notification message =
  Hh.div
    [ Hx.swap_oob "afterbegin:#notifications" ]
    [ Hh.li [] [ H.txt "%s" message ] ]
;;

let chatroom username =
  Hh.div
    [ Hx.ws_connect "/chatroom?username=%s" username; Hx.ext "ws" ]
    [ message_input ]
;;

let broadcasted_message message count =
  Dream_html.HTML.null
    [ render_message ~swap_oob:true message
    ; message_count ~swap_oob:true count
    ]
;;

let nav _msg_cnt =
  Hh.nav
    [ Hh.class_ "navbar sticky-top" ]
    [ Hh.div
        [ Hh.class_ "container-fluid" ]
        [ Hh.a [ Hh.class_ "navbar-brand" ] [ H.txt "BOB Chat" ] ]
    ]
;;

let login_page req =
  Hh.form
    [ Hx.post "/login"; Hx.target "body"; Hx.swap "outerHTML" ]
    [ H.csrf_tag req
    ; Hh.label
        [ Hh.for_ "#username"; Hh.class_ "form-label" ]
        [ H.txt "Username" ]
    ; Hh.input
        [ Hh.type_ "text"
        ; Hh.name "username"
        ; Hh.id "username"
        ; Hh.class_ "form-control"
        ; Hh.placeholder "Your username"
        ; Hh.autofocus
        ; Hh.required
        ]
    ; Hh.button
        [ Hh.type_ "submit"; Hh.class_ "btn btn-primary" ]
        [ H.txt "Login" ]
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
             @ content)
        ]
    ]
;;

module Page = struct
  let chat_app username messages =
    [ Hh.div
        [ Hh.class_ "row" ]
        [ Hh.div [ Hh.class_ "col-9" ] [ render_messages messages ]
        ; Hh.div [ Hh.class_ "col-3" ] [ notifications ]
        ]
    ; chatroom username
    ]
    |> base
  ;;

  let login req = login_page req |> return |> base
end
