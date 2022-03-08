import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/result.{map_error, then}
import gleam/string
import gleam/map.{Map}
import gleam/int
import gleam/http.{Get, Post}
import gleam/http/elli
import gleam/http/service
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/option.{None, Option, Some}
import gleam/json.{Json, array, int, nullable, object, string}
import gleam/dynamic
import handlers/logger

pub opaque type Service {
  Service(pets: Map(Int, Pet))
}

pub fn new_service() -> Service {
  Service(pets: map.new())
}

fn error(code: Int, message: String) -> Json {
  object([#("code", int(code)), #("message", string(message))])
}

fn not_found() {
  let body =
    "There's nothing here."
    |> bit_builder.from_string

  response.new(404)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/plain")
}

fn create_pet(
  _service: Service,
) -> fn(Request(BitString)) -> Response(BitBuilder) {
  fn(request: Request(BitString)) {
    case request.body
    |> bit_string.to_string
    |> map_error(fn(_) -> json.DecodeError { json.UnexpectedEndOfInput })
    |> then(pet_from_json) {
      Ok(_) ->
        response.new(201)
        |> response.set_body(bit_builder.from_string(""))
      Error(_) -> {
        let reply =
          error(400, "invalid request")
          |> json.to_string
        response.new(400)
        |> response.set_body(bit_builder.from_string(reply))
        |> response.prepend_header("content-type", "application/json")
      }
    }
  }
}

fn pet(_: Service) -> fn(String) -> Response(BitBuilder) {
  fn(id) {
    case int.parse(id) {
      Error(_) -> {
        let reply =
          error(400, "id is not a valid number")
          |> json.to_string
        response.new(400)
        |> response.set_body(bit_builder.from_string(reply))
        |> response.prepend_header("content-type", "application/json")
      }
      Ok(id) -> {
        let reply =
          Pet(id: id, name: "tom", tag: None)
          |> pet_to_json
          |> json.to_string
        response.new(200)
        |> response.set_body(bit_builder.from_string(reply))
        |> response.prepend_header("content-type", "application/json")
      }
    }
  }
}

type Pet {
  Pet(id: Int, name: String, tag: Option(String))
}

fn pet_to_json(pet: Pet) -> Json {
  object([
    #("id", int(pet.id)),
    #("name", string(pet.name)),
    #("tag", nullable(pet.tag, string)),
  ])
}

fn pet_from_json(json_string: String) -> Result(Pet, json.DecodeError) {
  let pet_decoder =
    dynamic.decode3(
      Pet,
      dynamic.field("id", of: dynamic.int),
      dynamic.field("name", of: dynamic.string),
      dynamic.field("tag", of: dynamic.optional(dynamic.string)),
    )

  json.decode(from: json_string, using: pet_decoder)
}

fn pets(_: Service) -> fn() -> Response(BitBuilder) {
  fn() {
    let reply =
      array([Pet(id: 9, name: "tom", tag: Some("tag"))], of: pet_to_json)
      |> json.to_string

    response.new(200)
    |> response.set_body(bit_builder.from_string(reply))
    |> response.prepend_header("content-type", "application/json")
  }
}

fn route(service: Service) -> fn(Request(BitString)) -> Response(BitBuilder) {
  fn(request) {
    let path = request.path_segments(request)

    case request.method, path {
      Post, ["pets"] -> create_pet(service)(request)
      Get, ["pets", id] -> pet(service)(id)
      Get, ["pets"] -> pets(service)()
      _, _ -> not_found()
    }
  }
}

pub fn handle(service: Service) {
  route(service)
  |> logger.middleware
}
