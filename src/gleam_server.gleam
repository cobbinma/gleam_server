import handlers/handlers
import service
import gleam/io
import gleam/int
import gleam/string
import gleam/result
import gleam/erlang
import gleam/erlang/os
import gleam/http/elli

pub fn main() {
  let port =
    os.get_env("PORT")
    |> result.then(int.parse)
    |> result.unwrap(3000)

  io.println(string.concat([
    "starting listening on localhost:",
    int.to_string(port),
    " 🐶",
  ]))

  assert Ok(_) =
    elli.become(handlers.handle(service.new_service()), on_port: port)
}
