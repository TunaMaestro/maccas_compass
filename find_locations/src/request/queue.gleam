import gleam/deque.{type Deque}
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/io
import gleam/otp/actor
import gleam/result
import gleam/string

type State(a) {
  State(queue: Deque(Request), self: process.Subject(Message(a)))
}

pub type Request {
  Request(caller: Subject(String), url: String)
}

/// Creates the actor and begins dequeing
pub fn start() -> Subject(Message(Request)) {
  let queue = deque.new()
  let assert Ok(self) =
    actor.start_spec(actor.Spec(
      init: fn() {
        let self_subj = process.new_subject()
        io.println_error("subject init: \t" <> string.inspect(self_subj))
        actor.Ready(
          State(queue: queue, self: self_subj),
          process.new_selector()
            |> process.selecting(self_subj, function.identity),
        )
      },
      init_timeout: 10,
      loop: handle_message,
    ))
  process.send(self, Dequeue)
  io.println_error("subject start: \t" <> string.inspect(self))
  self
}

// First step of implementing the stack Actor is to define the message type that
// it can receive.
//
// The type of the elements in the stack is not fixed so a type parameter is used
// for it instead of a concrete type such as `String` or `Int`.
pub opaque type Message(task) {
  // The `Shutdown` message is used to tell the actor to stop.
  // It is the simplest message type, it contains no data.
  Shutdown

  Enqueue(task)
  Dequeue
  Respond(Request)
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
  message: Message(Request),
  state: State(e),
) -> actor.Next(Message(e), State(e)) {
  case message {
    // For the `Shutdown` message we return the `actor.Stop` value, which causes
    // the actor to discard any remaining messages and stop.
    Shutdown -> actor.Stop(process.Normal)

    Enqueue(task) -> {
      // io.println_error("Enqueing <" <> task.url <> ">")
      let next_state =
        State(..state, queue: state.queue |> deque.push_back(task))
      actor.continue(next_state)
    }

    Dequeue -> {
      // io.print_error("Dequeing:\t")
      let State(queue, self) = state
      let queue = case deque.pop_front(queue) {
        Error(_) -> queue
        Ok(#(request, queue)) -> {
          // io.println_error("Dequeue found a request")
          // io.debug(request)
          // io.debug(queue)
          process_request(request, self)
          queue
        }
      }
      let state = State(queue, self)
      // process.send_after(process.new_subject(), 10, Dequeue)

      // io.println_error("subject dq: \t" <> string.inspect(self))
      process.send_after(self, 10, Dequeue)
      actor.continue(state)
    }

    Respond(Request(caller, url)) -> {
      let response = http_request(url)
      process.send(caller, response)
      actor.continue(state)
    }
    // For the `Push` message we add the new element to the stack and return
    // `actor.continue` with this new stack, causing the actor to process any
    // queued messages or wait for more.
    // Respond(client, value) -> {
    //   let contained =
    //     state
    //     |> list.filter(fn(town) { rectangle.contains(town.coords, in: value) })
    //   process.send(client, contained)
    //   actor.continue(state)
    // }
  }
}

fn process_request(request: Request, queue: Subject(Message(_))) -> Nil {
  process.send(queue, Respond(request))
}

fn http_request(url: String) -> String {
  "response: " <> url
}

pub fn new_request(url: String) -> Message(Request) {
  new_request_subj(process.new_subject(), url)
}

pub fn new_request_subj(subject s, url url: String) {
  io.println_error(
    "subject owner outer owner: " <> string.inspect(process.subject_owner(s)),
  )
  Enqueue(Request(s, url))
}

pub fn shutdown(s: Subject(Message(a))) -> Nil {
  process.send(s, Shutdown)
}
