module Id = Common.Id
module H = Dream_html
module Hh = H.HTML
module D = Basic__data

let render_contact_tr ({ name; address; _ } : D.contact) =
  Hh.tr [] [ Hh.td [] [ H.txt "%s" name ]; Hh.td [] [ H.txt "%s" address ] ]
;;

let render_contact_trs = List.map render_contact_tr
let render_contact_tbody contacts = Hh.tbody [] (render_contact_trs contacts)

let render_contact_thead =
  Hh.thead
    []
    [ Hh.tr [] [ Hh.th [] [ H.txt "Name" ]; Hh.td [] [ H.txt "Address" ] ] ]
;;

let render_contacts contacts =
  Hh.table
    [ Hh.class_ "table table-striped"; Hh.id "contacts" ]
    [ render_contact_thead; render_contact_tbody contacts ]
;;

let render_index content =
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
            [ Hh.class_ "container" ]
            ([ Hh.script [ Hh.src "https://unpkg.com/htmx.org@1.9.10" ] "" ]
             @ content)
        ]
    ]
;;

let render_form req =
  Hh.div
    []
    [ Hh.h1 [] [ H.txt "New Contact" ]
    ; Hh.form
        [ Hh.method_ `POST; Hh.action "/" ]
        [ H.csrf_tag req
        ; Hh.label [ Hh.class_ "form-label"; Hh.for_ "#name" ] [ H.txt "Name" ]
        ; Hh.input
            [ Hh.class_ "form-control"
            ; Hh.type_ "text"
            ; Hh.required
            ; Hh.id "name"
            ; Hh.name "name"
            ]
        ; Hh.label
            [ Hh.class_ "form-label"; Hh.for_ "#address" ]
            [ H.txt "Address" ]
        ; Hh.input
            [ Hh.class_ "form-control"
            ; Hh.type_ "text"
            ; Hh.required
            ; Hh.id "address"
            ; Hh.name "address"
            ]
        ; Hh.button
            [ Hh.class_ "btn btn-success"; Hh.type_ "submit" ]
            [ H.txt "submit" ]
        ]
    ]
;;

let render_search_form query =
  Hh.div
    []
    [ Hh.h2 [] [ H.txt "Search" ]
    ; Hh.form
        [ Hh.method_ `GET; Hh.action "/" ]
        [ Hh.label
            [ Hh.class_ "form-label"; Hh.for_ "#query" ]
            [ H.txt "Query" ]
        ; Hh.input
            [ Hh.class_ "form-control"
            ; Hh.id "query"
            ; Hh.name "query"
            ; Hh.type_ "search"
            ]
        ; Hh.button
            [ Hh.class_ "btn btn-info"; Hh.type_ "submit" ]
            [ H.txt "search" ]
        ]
    ]
;;

let render_total_contacts_count cnt =
  let id = "total-contacts-count" in
  Hh.span
    [ Hh.id "%s" id ]
    [ H.txt "Total number of contacts:"; H.txt "%i" cnt ]
;;

let render_filtered_contacts_count cnt =
  let id = "filtered-contacts-count" in
  Hh.span
    [ Hh.id "%s" id ]
    [ H.txt "Number filtered of contacts:"; H.txt "%i" cnt ]
;;

let contacts_page req query total_count contacts =
  render_index
    [ Hh.div
        [ Hh.class_ "row" ]
        [ Hh.div [ Hh.class_ "col-6" ] [ render_form req ]
        ; Hh.div
            [ Hh.class_ "col-6" ]
            [ render_search_form query
            ; render_total_contacts_count total_count
            ; render_filtered_contacts_count (List.length contacts)
            ; render_contacts contacts
            ]
        ]
    ]
;;

let handle_get_index req =
  Dream.sql req (fun (module Db) ->
    let module Repo = Basic__repo.Make_repo (Db) in
    let q = Dream.query req "query" in
    let m =
      match q with
      | None | Some "" -> Repo.list ()
      | Some q -> Repo.search q
    in
    Lwt.bind m (function
      | Error err -> Dream.html ~status:`Internal_Server_Error err
      | Ok contacts ->
        Lwt.bind (Repo.count ()) (fun total_count ->
          contacts_page req (Option.value ~default:"" q) total_count contacts
          |> Dream_html.respond)))
;;

let handle_post_index req =
  Lwt.bind (Dream.form req) (function
    | `Ok [ ("address", address); ("name", name) ] ->
      Dream.sql req (fun (module Db) ->
        let module Repo = Basic__repo.Make_repo (Db) in
        let contact = D.fresh_contact name address in
        Lwt.bind (Repo.save contact) (function
          | Error err -> Dream.html ~status:`Internal_Server_Error err
          | Ok () -> Dream.redirect req "/"))
    | _ -> Dream.html ~status:`Bad_Request "missing parameters")
;;

let routes =
  [ Dream.get "/" handle_get_index; Dream.post "/" handle_post_index ]
;;

let main () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sql_pool "sqlite3:contacts.sqlite?create=true&write=true"
  @@ Dream.memory_sessions
  @@ Dream.router routes
;;
