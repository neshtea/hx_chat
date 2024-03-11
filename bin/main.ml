let hx_chat db_file = Hx.Main.main db_file

let db_file =
  let doc = "Path to a sqlite database file." in
  Cmdliner.Arg.(value @@ opt string "db.sqlite" @@ info [ "db_file" ] ~doc)
;;

let hx_chat_cmd =
  let doc = "Run the hx_chat webserver." in
  let info = Cmdliner.Cmd.info "hx_chat" ~doc in
  Cmdliner.Cmd.v info Cmdliner.Term.(const hx_chat $ db_file)
;;

let () = exit (Cmdliner.Cmd.eval hx_chat_cmd)
