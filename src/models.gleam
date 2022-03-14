import gleam/option.{Option}

pub type Pet {
  Pet(id: Int, name: String, tag: Option(String))
}
