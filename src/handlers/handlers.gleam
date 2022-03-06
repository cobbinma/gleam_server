import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/result
import gleam/string
import gleam/map.{Map}
import gleam/int
import gleam/http.{Get, Post}
import gleam/http/elli
import gleam/http/service
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/option.{None, Option, Some}
import gleam/json.{Json, array, int, null, object, string}
import handlers/logger

pub opaque type Service {
  Service(pets: Map(Int, Pet))
}

pub fn new_service() -> Service {
  Service(pets: map.new())
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
  _request: Service,
) -> fn(Request(BitString)) -> Response(BitBuilder) {
  fn(_request) {
    response.new(201)
    |> response.set_body(bit_builder.from_string(""))
  }
}

fn pet(_: Service) -> fn(String) -> Response(BitBuilder) {
  fn(id) {
    let id =
      int.parse(id)
      |> result.unwrap(0)

    let reply =
      Pet(id: id, name: "tom", tag: None)
      |> pet_to_json
      |> json.to_string

    response.new(200)
    |> response.set_body(bit_builder.from_string(reply))
    |> response.prepend_header("content-type", "application/json")
  }
}

type Pet {
  Pet(id: Int, name: String, tag: Option(String))
}

fn pet_to_json(pet: Pet) -> Json {
  object([
    #("id", int(pet.id)),
    #("name", string(pet.name)),
    #(
      "tag",
      case pet.tag {
        Some(tag) -> string(tag)
        None -> null()
      },
    ),
  ])
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
