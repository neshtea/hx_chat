type contact =
  { id : Common.Id.t
  ; name : string
  ; address : string
  ; created_at : Common.Timestamp.t
  }

let make_contact id name address created_at = { id; name; address; created_at }

let fresh_contact name address =
  make_contact (Common.Id.gen ()) name address (Common.Timestamp.now ())
;;
