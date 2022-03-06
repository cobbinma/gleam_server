import gleam/bit_builder
import gleam/bit_string
import gleam/result
import gleam/string
import gleam/int
import gleam/http.{Get, Post}
import gleam/http/elli
import gleam/http/service
import gleam/http/request
import gleam/http/response
import gleam/option.{None, Option, Some}
import gleam/json.{Json, array, int, null, object, string}
import handlers/logger

fn not_found() {
  let body =
    "There's nothing here."
    |> bit_string.from_string

  response.new(404)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/plain")
}

fn create_pet(_request) {
  response.new(201)
  |> response.set_body(bit_string.from_string(""))
}

fn pet(id) {
  let id =
    int.parse(id)
    |> result.unwrap(0)

  let reply =
    Pet(id: id, name: "tom", tag: None)
    |> pet_to_json
    |> json.to_string

  response.new(200)
  |> response.set_body(bit_string.from_string(reply))
  |> response.prepend_header("content-type", "application/json")
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

fn pets() {
  let reply =
    array([Pet(id: 9, name: "tom", tag: Some("tag"))], of: pet_to_json)
    |> json.to_string

  response.new(200)
  |> response.set_body(bit_string.from_string(reply))
  |> response.prepend_header("content-type", "application/json")
}

pub fn service(request) {
  let path = request.path_segments(request)

  case request.method, path {
    Post, ["pets"] -> create_pet(request)
    Get, ["pets", id] -> pet(id)
    Get, ["pets"] -> pets()
    _, _ -> not_found()
  }
}

pub fn handle() {
  service
  |> service.map_response_body(bit_builder.from_bit_string)
  |> logger.middleware
}
