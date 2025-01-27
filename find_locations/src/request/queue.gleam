import gleam/deque.{type Deque}
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/io
import gleam/otp/actor
import gleam/string

const dequeue_delay = 0

type State(query, response) {
  State(
    queue: Deque(Request(query, response)),
    self: process.Subject(Message(query, response)),
    callback: Callback(query, response),
    request_count: Int,
  )
}

pub type Callback(query, response) =
  fn(query) -> response

pub type Request(query, response) {
  Request(caller: Subject(response), query: query)
}

/// Creates the actor and begins dequeing
pub fn start(
  callback sync_fn: Callback(query, response),
) -> Subject(Message(query, response)) {
  let assert Ok(self) =
    actor.start_spec(actor.Spec(
      init: init(sync_fn),
      init_timeout: 10,
      loop: handle_message,
    ))

  // Begin the dequeue loop
  process.send(self, Dequeue)
  self
}

fn init(sync_fn) {
  fn() {
    let self_subj = process.new_subject()
    // io.println_error("subject init: \t" <> string.inspect(self_subj))
    let queue = deque.new()
    actor.Ready(
      State(queue: queue, self: self_subj, callback: sync_fn, request_count: 0),
      process.new_selector()
        |> process.selecting(self_subj, function.identity),
    )
  }
}

pub opaque type Message(query, response) {
  Shutdown

  Enqueue(Request(query, response))
  Dequeue
  Respond(Request(query, response))
}

fn handle_message(
  message: Message(query, response),
  state: State(query, response),
) -> actor.Next(Message(query, response), State(query, response)) {
  case message {
    // For the `Shutdown` message we return the `actor.Stop` value, which causes
    // the actor to discard any remaining messages and stop.
    Shutdown -> actor.Stop(process.Normal)

    Enqueue(task) -> {
      let next_state =
        State(..state, queue: state.queue |> deque.push_back(task))
      actor.continue(next_state)
    }

    Dequeue -> {
      let State(queue, self, _, _) = state
      let queue = case deque.pop_front(queue) {
        Error(_) -> queue
        Ok(#(request, queue)) -> {
          process_request(request, self)
          queue
        }
      }
      let state = State(..state, queue:)

      process.send_after(self, dequeue_delay, Dequeue)
      actor.continue(state)
    }

    Respond(Request(caller, query)) -> {
      let response = state.callback(query)
      process.send(caller, response)
      io.println_error(
        "\u{1b}[31mRequest #"
        <> string.pad_start(int.to_string(state.request_count), 4, " ")
        <> "\u{1b}[m",
      )
      actor.continue(State(..state, request_count: state.request_count + 1))
    }
  }
}

fn process_request(
  req: Request(query, response),
  self: Subject(Message(query, response)),
) -> Nil {
  process.send(self, Respond(req))
}

pub fn new_request(
  subject subject: Subject(response),
  query query: a,
) -> Message(a, response) {
  Enqueue(Request(subject, query))
}

pub fn shutdown(s: Subject(Message(a, b))) -> Nil {
  process.send(s, Shutdown)
}
