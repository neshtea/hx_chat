module Id = Common.Id
module Timestamp = Common.Timestamp

module Message = struct
  type t =
    { id : Id.t
    ; username : string
    ; content : string
    ; timestamp : Timestamp.t
    }

  let make id username content timestamp = { id; username; content; timestamp }

  (* stateful helper function to generate messages. *)
  let fresh username content =
    make (Id.gen ()) username content (Timestamp.now ())
  ;;

  let id { id; _ } = id
  let username { username; _ } = username
  let content { content; _ } = content
  let timestamp { timestamp; _ } = timestamp
end

module User = struct
  type t = string

  let make s = s
  let name s = s
end

module Id_map = Map.Make (Common.Id)

module Chat_room = struct
  module type CLIENT = sig
    type t

    val send : string -> t -> unit Lwt.t
  end

  module type S = sig
    type elt
    type t

    val empty : t
    val broadcast : ?exclude:Id.t list -> string -> t -> unit Lwt.t
    val whisper : string -> Id.t -> t -> unit Lwt.t
    val connection : Id.t -> t -> elt option
    val connect : User.t -> elt -> t -> Id.t
    val disconnect : Id.t -> t -> unit
  end

  module Make (C : CLIENT) : S with type elt = C.t = struct
    type elt = C.t
    type member = User.t * elt
    type t = { mutable clients : member Id_map.t }

    let empty = { clients = Id_map.empty }

    let broadcast ?(exclude = []) content { clients; _ } =
      clients
      |> Id_map.to_list
      |> Lwt_list.iter_p (fun (id, (_, client)) ->
        if List.mem id exclude then Lwt.return_unit else C.send content client)
    ;;

    let whisper content id { clients; _ } =
      match Id_map.find_opt id clients with
      | None -> Lwt.return_unit
      | Some (_user, client) -> C.send content client
    ;;

    let connection client_id { clients; _ } =
      Id_map.find_opt client_id clients
      |> Option.map (fun (_, client) -> client)
    ;;

    let report chat_room =
      let conns = chat_room.clients in
      Id_map.bindings conns
      |> List.map (fun (id, _) -> Common.Id.to_string id)
      |> String.concat ","
      |> Dream.log "connected clients: %i (%s)%!" (Id_map.cardinal conns)
    ;;

    let connect user client chat_room =
      let client_id = Common.Id.gen () in
      chat_room.clients <- Id_map.add client_id (user, client) chat_room.clients;
      report chat_room;
      client_id
    ;;

    let disconnect client_id chat_room =
      chat_room.clients <- Id_map.remove client_id chat_room.clients;
      report chat_room
    ;;
  end
end
