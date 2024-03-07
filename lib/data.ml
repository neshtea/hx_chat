module Message = struct
  module Id = Common.Id
  module Timestamp = Common.Timestamp

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

module Id_map = Map.Make (Common.Id)

module Chat_room = struct
  type t = { mutable connections : Dream.websocket Id_map.t }

  let make websockets = { connections = websockets }
  let empty = make Id_map.empty
  let connections { connections; _ } = connections

  let broadcast content { connections; _ } =
    connections
    |> Id_map.to_list
    |> Lwt_list.iter_p (fun (_, websocket) -> Dream.send websocket content)
  ;;

  let report chat_room =
    let conns = chat_room.connections in
    Id_map.bindings conns
    |> List.map (fun (id, _) -> Common.Id.to_string id)
    |> String.concat ","
    |> Dream.log "connected clients: %i (%s)%!" (Id_map.cardinal conns)
  ;;

  let connect websocket chat_room =
    let client_id = Common.Id.gen () in
    chat_room.connections
    <- Id_map.add client_id websocket chat_room.connections;
    report chat_room;
    client_id
  ;;

  let disconnect client_id chat_room =
    chat_room.connections <- Id_map.remove client_id chat_room.connections;
    report chat_room
  ;;
end
