(lang dune 3.12)

(name hx_chat)

(generate_opam_files true)

(source
 (github neshtea/hx_chat))

(authors "Marco Schneider")

(maintainers "Marco Schneider")

(license MIT)

(package
 (name hx_chat)
 (synopsis "Small example of ocaml with htmx, implementing a chat room.")
 (description "Small example of ocaml with htmx, implementing a chat room.")
 (depends
  ocaml
  dune
  dream
  dream-html
  ptime
  uuidm
  yojson
  caqti
  caqti-driver-sqlite3
  caqti-lwt)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
