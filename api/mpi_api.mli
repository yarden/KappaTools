exception BadResponse of Mpi_message_j.response_content

val on_message : Api.manager -> (string -> unit Lwt.t) -> string -> unit Lwt.t

class type virtual manager_base_type =
  object
    method private virtual message :
      Mpi_message_j.request ->
      Mpi_message_j.response_content Mpi_message_j.result Lwt.t

    inherit Api.manager
end

class virtual manager_base : unit -> manager_base_type

class type virtual manager_mpi_type =
  object
    method private virtual post_message : string -> unit
    method private virtual sleep : float -> unit Lwt.t
    method private message :
      Mpi_message_j.request -> Mpi_message_j.response Lwt.t
    method private receive : string -> unit

    inherit Api.manager
    method virtual is_running : bool
  end

class virtual manager : unit -> manager_mpi_type
