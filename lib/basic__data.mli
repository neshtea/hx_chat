type contact =
  { id : Common.Id.t
  ; name : string
  ; address : string
  ; created_at : Common.Timestamp.t
  }

val make_contact
  :  Common.Id.t
  -> string
  -> string
  -> Common.Timestamp.t
  -> contact

val fresh_contact : string -> string -> contact
