import coordinates
import fake_server.{Town}
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleeunit/should
import rectangle
import rectangle_debug
import tuple
import vector

pub fn setup_test() {
  let actor = fake_server.start()
}

pub fn request_one_test() {
  // testing:
  // 176	Braidwood	Australia	-35.43889069998469	149.7955552
  let actor = fake_server.start()
  let assert Ok(braidwood_bound) =
    rectangle.new(vector.Vec(149.78, -35.45), vector.Vec(149.9, -35.42))

  let r = process.call(actor, fake_server.Query(_, query: braidwood_bound), 2)

  r
  |> should.equal([
    Town("Braidwood", vector.Vec(149.7955552, -35.43889069998469)),
  ])
}

pub fn request_all_test() {
  // testing:
  // bound box over Australia
  // 113.338953078, -43.6345972634, 153.6380696, -10.6681857235
  let actor = fake_server.start()
  let assert Ok(aus_bound) =
    rectangle.new_raw(
      113.338953078,
      -43.6345972634,
      153.6380696,
      -10.6681857235,
    )

  let r = process.call(actor, fake_server.Query(_, query: aus_bound), 2)
  let assert Ok(towns) = fake_server.towns() |> result.all

  let exceptions = ["Burnt Pine", "Thursday Island", "Lord Howe Island"]

  set.difference(set.from_list(towns), set.from_list(r))
  |> set.filter(fn(x) { !list.contains(exceptions, x.name) })
  |> set.to_list
  |> should.equal([])
}

pub fn request_shutdown_test() {
  let actor = fake_server.start()
  let assert Ok(braidwood_bound) =
    rectangle.new(vector.Vec(149.78, -35.45), vector.Vec(149.9, -35.42))

  process.send(actor, fake_server.Shutdown)
  process.try_call(actor, fake_server.Query(_, query: braidwood_bound), 2)
  |> should.be_error
}

pub fn rectangle_test() {
  let actor = fake_server.start()
  let assert Ok(aus_bound) =
    rectangle.new_raw(
      113.338953078,
      -43.6345972634,
      153.6380696,
      -10.6681857235,
    )

  let r = process.call(actor, fake_server.Query(_, query: aus_bound), 2)
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
