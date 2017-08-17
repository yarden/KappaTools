(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

open Lwt.Infix
open Cohttp_lwt_unix

type context = { arguments : (string * string) list
               ; connection : Cohttp_lwt_unix.Server.conn
               ; request : Cohttp.Request.t
               ; body : Cohttp_lwt_body.t }
(* Default headers for http requests note support has been
   added for CORS headers.
*)
let headers =
  let h = Cohttp.Header.init_with "Access-Control-Allow-Origin" "*" in
  let h = Cohttp.Header.add h "content-type" "application/json" in
  h

(* Given a result and a way to serialize a success result, return
   to client the the http response.
*)
let result_response
    ~(string_of_success: 'ok -> string)
  : 'ok Api.result -> (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t =
  Api_common.result_map
    ~ok:(fun (code : Api.manager_code)
          (ok : 'a) ->
          let body : string = string_of_success ok in
          let status :> Cohttp.Code.status_code = code in
          Server.respond_string ~headers ~status ~body ())
    ~error:(fun
             (code : Api.manager_code)
             (errors : Api_types_j.errors) ->
             let error_msg : string = Api_types_j.string_of_errors errors in
             let status :> Cohttp.Code.status_code = code in
             (Lwt_log_core.log ~level:Lwt_log_core.Error error_msg)
             >>= (fun _ ->
                 Server.respond_string
                   ?headers:(Some headers)
                   ~status:status
                   ~body:error_msg
                   ()))

let string_response ?(headers=headers) = Server.respond_string ~headers

let error_response
    ?(headers = headers)
    ?(status = `Internal_server_error)
    ~(errors : Api_types_j.errors)
  : (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t =
  let error_msg : string = Api_types_j.string_of_errors errors in
  let () =
    Lwt.async
      (fun () ->
         Lwt_log_core.log
           ~level:Lwt_log_core.Debug
           (Format.sprintf " + error : %s" error_msg))
  in
  Server.respond_string
    ~headers
    ~status
    ~body:error_msg
    ()

let not_found path : (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t =
  let headers = Cohttp.Header.replace headers "content-type" "text/html" in
  let body = "<html><body><h1>Unknown path \""^path^"\"</h1></body></html>" in
  Server.respond_string ~headers ~status:`Not_found ~body ()

type 'a route =
  { path : string ;
    methods : Cohttp.Code.meth list ;
    operation : 'a }

type route_handler =
  (context:context ->
   (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t)
    route

type route_filter =
  (context:context ->
   chain:(context:context -> (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t) ->
   (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t)
    route

type url_matcher =
  { re : Re.re;
    labels : string list ;
    route : string }

let variable_pattern =
  Re.compile (Re.seq [Re.char '{'; Re.rep1 (Re.alt [Re.alnum; Re.char '_']); Re.char '}'])
let label_pattern = Re.compile (Re.rep1 (Re.alt [Re.alnum; Re.char '_']))

let create_url_matcher (url : string) : url_matcher =
  let labels = Re.matches variable_pattern url in
  let labels =
    List.flatten
      (List.map
         (Re.matches label_pattern)
         labels)
  in
  let pattern =
    Re.split_full variable_pattern url |>
    List.map (function
    | `Text s -> Re.str s
    | `Delim _ -> Re.group (Re.rep (Re.compl [Re.char '/']))) |>
    Re.seq |> Re.whole_string in
  let () =
    Lwt.async
      (fun () ->
         Lwt_log_core.log
           ~level:Lwt_log_core.Debug
           (Format.sprintf " + route : %s" (Format.asprintf "%a" Re.pp pattern)))
  in
  let re = Re.compile pattern in
  { re = re;
    labels = labels ;
    route = url ; }

let rec match_url
    (url_matchers : ('a * url_matcher) list)
    (url : string)
  : ('a * (string * string) list) list =
  match url_matchers with
  | (arg,matcher)::tail ->
    (try
       let matching =
         Re.exec matcher.re url |>
         Re.Group.all |>
         Array.to_list |> List.tl in
       let get_parameters : (string * string) list =
         List.combine matcher.labels matching in
       let () =
         Lwt.async
           (fun () ->
              Lwt_log_core.log_f
                ~level:Lwt_log_core.Debug
                "match_url :\n+ url : '%s'\n+ route: '%s'\n+ args: { %a }"
                url matcher.route
                (fun () -> Format.asprintf "@[%a@]"
                    (Pp.list Pp.comma
                       (fun f (key,value) -> Format.fprintf f "%s: %s" key value)))
                get_parameters) in
       [arg,get_parameters]
     with Not_found -> [])
    @(match_url tail url)
  | [] -> []

let option_handler _ matches =
  let methods =
    List.flatten
      (List.map
         (fun route -> route.methods)
         (List.map fst matches))
  in
  let h =
    Cohttp.Header.init_with
      "Access-Control-Allow-Origin"
                 "*"
  in
  let h =
    Cohttp.Header.add
      h
      "Access-Control-Allow-Methods"
      (String.concat
         " , "
         (List.map Cohttp.Code.string_of_method methods))
  in
  let h =
    Cohttp.Header.add
      h
      "Access-Control-Request-Headers" "X-Custom-Header"
  in
  Server.respond_string
    ?headers:(Some h)
    ~status:`OK
    ~body:""
    ()

let request_handler context matchers =
  let matchers =
    List.filter
      (* only select handlers where the method matches *)
      (fun (route,_) ->
         List.mem
           context.request.Cohttp.Request.meth
           route.methods)
      matchers
  in
  match matchers with
  | [] -> not_found (Uri.path (Request.uri context.request))
  | (route,arguments)::[]  ->
    Lwt.catch
      (fun () ->
         let context = { context with arguments = arguments } in
         route.operation ~context
        )
        (fun exn ->
           result_response
             ~string_of_success:(fun x -> x)
             (match exn with
              | Yojson.Json_error e -> (Api_common.result_error_msg e)
              | Ag_oj_run.Error e -> (Api_common.result_error_msg e)
              | exn -> (Api_common.result_error_exception exn)
             )
        )
  | _::_ ->
    error_response
      ?headers:None
      ?status:None
      ~errors:(Api_data.api_message_errors "multiple routes match url")


let route_handler
    (routes : route_handler list) :
  context:context -> (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t =
  let url_matchers : (route_handler * url_matcher ) list =
    List.map
      (fun route ->
         (route,create_url_matcher route.path))
      routes
  in
  fun ~context ->
    let url : string =
      Uri.pct_decode
        (Uri.path
           (Cohttp.Request.uri context.request))
    in

    (if context.request.Request.meth = `OPTIONS then
       option_handler
     else
       request_handler
    )
    context
    (* get the list of matching handlers with their arguments *)
    (match_url url_matchers url)
