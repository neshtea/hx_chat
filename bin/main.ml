let hx_chat db_file interface port = Hx.Main.main db_file interface port

let db_file =
  let doc = "Path to a sqlite database file." in
  Cmdliner.Arg.(value @@ opt string "db.sqlite" @@ info [ "db_file" ] ~doc)
;;

let interface =
  let doc =
    "String representation of the interface the server should serve at."
  in
  Cmdliner.Arg.(value @@ opt string "localhost" @@ info [ "interface" ] ~doc)
;;

let port =
  let doc = "Port the server should listen on." in
  Cmdliner.Arg.(value @@ opt int 8080 @@ info [ "port" ] ~doc)
;;

let hx_chat_cmd =
  let doc = "Run the hx_chat webserver." in
  let info = Cmdliner.Cmd.info "hx_chat" ~doc in
  Cmdliner.Cmd.v info Cmdliner.Term.(const hx_chat $ db_file $ interface $ port)
;;

let () = exit (Cmdliner.Cmd.eval hx_chat_cmd)
