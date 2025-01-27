import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/result
import gleam/string
import rectangle
import simplifile
import vector

type State {
  State(List(Town), request_count: Int)
}

pub type Town {
  Town(name: String, coords: vector.Vec)
}

pub opaque type Server {
  Server(Subject(Message(rectangle.Rectangle)))
}

const filename = "test/aus_towns.tsv"

pub fn towns() {
  let assert Ok(towns) = simplifile.read(filename)

  towns
  |> string.split("\n")
  // header
  |> list.drop(1)
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(fn(line) {
    let line = string.trim(line)
    let fields =
      line
      |> string.split("\t")
    case fields {
      [_id, name, _country, lat, lon] -> {
        use lat <- result.try(float.parse(lat))
        use lon <- result.map(float.parse(lon))
        Town(name:, coords: vector.Vec(lon, lat))
      }
      _ -> {
        Error(Nil)
      }
    }
    |> result.map_error(fn(_) { line })
  })
}

pub fn start() -> Server {
  let state = case towns() |> result.all {
    Ok(state) -> State(state, 0)
    Error(msg) -> panic as { "Failed to parse '" <> msg <> "'" }
  }
  let assert Ok(self) = actor.start(state, handle_message)
    as "Couldn't start actor"
  Server(self)
}

// First step of implementing the stack Actor is to define the message type that
// it can receive.
//
// The type of the elements in the stack is not fixed so a type parameter is used
// for it instead of a concrete type such as `String` or `Int`.
pub type Message(element) {
  // The `Shutdown` message is used to tell the actor to stop.
  // It is the simplest message type, it contains no data.
  Shutdown

  Query(reply_with: Subject(List(Town)), query: rectangle.Rectangle)
}

// The last part is to implement the `handle_message` callback function.
//
// This function is called by the Actor for each message it receives.
// Actor is single threaded and only does one thing at a time, so it handles
// messages sequentially and one at a time, in the order they are received.
//
// The function takes the message and the current state, and returns a data
// structure that indicates what to do next, along with the new state.
fn handle_message(
  message: Message(e),
  state: State,
) -> actor.Next(Message(e), State) {
  case message {
    // For the `Shutdown` message we return the `actor.Stop` value, which causes
    // the actor to discard any remaining messages and stop.
    Shutdown -> actor.Stop(process.Normal)

    // For the `Push` message we add the new element to the stack and return
    // `actor.continue` with this new stack, causing the actor to process any
    // queued messages or wait for more.
    Query(client, value) -> {
      io.println_error(
        "\u{1b}[31mRequest #"
        <> string.pad_start(int.to_string(state.request_count), 4, " ")
        <> "\u{1b}[m",
      )
      let State(towns, reqs) = state
      let contained =
        towns
        |> list.filter(fn(town) { rectangle.contains(town.coords, in: value) })
      process.send(client, contained)
      actor.continue(State(towns, reqs + 1))
    }
  }
}

pub fn actor(s: Server) -> process.Subject(_) {
  let Server(a) = s
  a
}
