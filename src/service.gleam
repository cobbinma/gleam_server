import models.{Pet}
import gleam/map.{Map}
import gleam/otp/actor.{Next}
import gleam/otp/process.{Sender}

pub opaque type Service {
  Service(sender: Sender(Message))
}

pub fn new_service() -> Service {
  assert Ok(sender) = actor.start(map.new(), handle_message)
  Service(sender: sender)
}

pub fn get_pet(service: Service, id: Int) -> Result(Pet, Nil) {
  let pets = process.call(service.sender, RequestPets, 100)
  map.get(pets, id)
}

pub fn get_pets(service: Service) -> List(Pet) {
  process.call(service.sender, RequestPets, 100)
  |> map.values
}

pub fn add_pet(service: Service, pet: Pet) -> Map(Int, Pet) {
  let pets = process.call(service.sender, RequestPets, 100)
  let new_pets = map.insert(pets, pet.id, pet)
  process.call(service.sender, fn(sender) { UpdatePets(sender, new_pets) }, 100)
}

type Message {
  RequestPets(reply_channel: Sender(Map(Int, Pet)))
  UpdatePets(reply_channel: Sender(Map(Int, Pet)), new_pets: Map(Int, Pet))
}

fn handle_message(msg: Message, pets: Map(Int, Pet)) -> Next(Map(Int, Pet)) {
  case msg {
    RequestPets(reply_channel) -> {
      process.send(reply_channel, pets)
      actor.Continue(pets)
    }
    UpdatePets(reply_channel, new_pets) -> {
      let pets = new_pets
      process.send(reply_channel, pets)
      actor.Continue(pets)
    }
  }
}
