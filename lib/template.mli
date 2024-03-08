(** Building blocks for the main application. *)
type html = Dream_html.node

(** {2 Utilities for small HTML responses} *)
val broadcasted_message : Data.Message.t -> int -> html

(** [notification message] is some html that represents the a notification that
    can be given to the client. *)
val notification : string -> html

(** [message_count count] is some html that represents the current message count
    in the application. *)
val message_count : ?swap_oob:bool -> int -> html

(** Collection of complete pages that can be send to the client as-is. *)
module Page : sig
  (** [chat_app username messages] is an html-page that shows the chat app for
      some user, shown as [username] and an initial list of [messages]. *)
  val chat_app : string -> Data.Message.t list -> html

  (** [login req] is an html-page that shows the login-form for the chat-app. *)
  val login : Dream.request -> html
end
