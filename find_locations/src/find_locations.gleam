import coordinates
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/result
import rectangle
import rectangle_debug
import request/fake_server
import tuple
import vector.{type Vec}

pub fn main() {
  io.println("Hello from find_locations!")
  fake_in_aus()
}

pub fn search(low: Vec, high: Vec) {
  todo
}

fn fake_in_aus() {
  let actor = fake_server.start()
  let assert Ok(aus_bound) =
    rectangle.new_raw(
      113.338953078,
      -43.6345972634,
      153.6380696,
      -10.6681857235,
    )

  let assert Ok(towns) = fake_server.towns() |> result.all
  let f = fn(rec: rectangle.Rectangle) {
    process.call(actor, fake_server.Query(_, query: rec), 2)
  }
  let res = coordinates.search_all(start_in: aus_bound, with: f)
  io.println_error("Results receieved, printing")
  rectangle_debug.debug_points(
    res |> list.map(tuple.fst),
    towns |> list.map(fn(t) { t.coords }),
  )
}
