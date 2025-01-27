import coordinates
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/task
import gleam/result
import gleam/string
import rectangle
import rectangle_debug
import request/fake_server
import request/queue
import tuple
import vector.{type Vec}

pub fn main() {
  // fake_in_aus()
  search(aus())
}

fn callback(
  server,
) -> queue.Callback(rectangle.Rectangle, List(fake_server.Town)) {
  fn(rec) {
    let res = process.call(server, fake_server.Query(_, query: rec), 2000)
    let len = list.length(res)
    let len = len |> int.to_string |> string.pad_start(4, " ")
    io.println("Search: " <> len <> string.inspect(res |> list.take(10)))
    res
  }
}

pub fn search(bound: rectangle.Rectangle) {
  let server = fake_server.start() |> fake_server.actor
  let self = process.new_subject()

  let cb = callback(server)
  let coordinator = queue.start(cb)

  coordinates.search_all(
    start_in: bound,
    with: fn(rec) {
      process.call(coordinator, queue.new_request(_, rec), within: 2000)
    },
    max_per_box: 20,
  )
}

fn aus() {
  let assert Ok(aus_bound) =
    rectangle.new_raw(
      113.338953078,
      -43.6345972634,
      153.6380696,
      -10.6681857235,
    )
  aus_bound
}

fn fake_in_aus() {
  let actor =
    fake_server.start()
    |> fake_server.actor

  let assert Ok(towns) = fake_server.towns() |> result.all
  let f = fn(rec: rectangle.Rectangle) {
    process.call(actor, fake_server.Query(_, query: rec), 2)
  }
  let res = coordinates.search_all(start_in: aus(), with: f, max_per_box: 1)
  io.println_error("Results receieved, printing")
  rectangle_debug.debug_points(
    res |> list.map(tuple.fst),
    towns |> list.map(fn(t) { t.coords }),
  )
}
