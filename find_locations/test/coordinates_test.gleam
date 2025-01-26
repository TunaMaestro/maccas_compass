import coordinates
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleeunit/should
import rectangle.{type Rectangle}
import rectangle_debug
import tuple
import vector

const point_of_interest = [
  vector.Vec(0.0, 0.0),
  vector.Vec(1.0, 1.0),
  vector.Vec(1.0, 6.0),
  vector.Vec(2.0, 0.0),
  vector.Vec(2.0, 2.0),
  vector.Vec(11.0, 14.0),
  vector.Vec(14.0, 7.0),
  // oob, so shouldn't be returned in search 
  vector.Vec(16.0, 16.0),
  vector.Vec(10_000.0, 0.0),
  vector.Vec(-1.0, -1.0),
]

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn rectangle_test() {
  rectangle.new(vector.Vec(3.0, 1.0), vector.Vec(5.0, 31.0))
  |> should.be_ok
  rectangle.new(vector.Vec(3.0, 1.0), vector.Vec(-5.0, 31.0))
  |> should.be_error
}

fn bounds() -> Rectangle {
  let assert Ok(rec) =
    rectangle.new(vector.Vec(0.0, 0.0), vector.Vec(16.0, 16.0))
  rec
}

pub fn quadrisect_test() {
  let rec = bounds()
  let assert Ok(exp) =
    [
      rectangle.new(vector.Vec(0.0, 0.0), vector.Vec(8.0, 8.0)),
      rectangle.new(vector.Vec(8.0, 0.0), vector.Vec(16.0, 8.0)),
      rectangle.new(vector.Vec(0.0, 8.0), vector.Vec(8.0, 16.0)),
      rectangle.new(vector.Vec(8.0, 8.0), vector.Vec(16.0, 16.0)),
    ]
    |> result.all
  let exp = set.from_list(exp)
  coordinates.quadrisect(rec)
  |> set.from_list
  |> should.equal(exp)
}

pub fn bisect_vertical_on_portrait_test() {
  let assert Ok(rec) =
    rectangle.new(vector.Vec(0.0, 0.0), vector.Vec(4.0, 16.0))
  let assert Ok(exp) =
    [
      rectangle.new(vector.Vec(0.0, 0.0), vector.Vec(4.0, 8.0)),
      rectangle.new(vector.Vec(0.0, 8.0), vector.Vec(4.0, 16.0)),
    ]
    |> result.all
  coordinates.bisect(rec)
  |> should.equal(exp)
}

pub fn bisect_horizontal_on_square_test() {
  let assert Ok(rec) = rectangle.new(vector.Vec(0.0, 0.0), vector.Vec(4.0, 4.0))
  let assert Ok(exp) =
    [
      rectangle.new(vector.Vec(0.0, 0.0), vector.Vec(2.0, 4.0)),
      rectangle.new(vector.Vec(2.0, 0.0), vector.Vec(4.0, 4.0)),
    ]
    |> result.all
  coordinates.bisect(rec)
  |> should.equal(exp)
}

pub fn bisect_twice_test() {
  let rec = bounds()
  let assert Ok(exp) =
    [
      rectangle.new(vector.Vec(0.0, 0.0), vector.Vec(8.0, 8.0)),
      rectangle.new(vector.Vec(8.0, 0.0), vector.Vec(16.0, 8.0)),
      rectangle.new(vector.Vec(0.0, 8.0), vector.Vec(8.0, 16.0)),
      rectangle.new(vector.Vec(8.0, 8.0), vector.Vec(16.0, 16.0)),
    ]
    |> result.all
  let exp = set.from_list(exp)
  coordinates.bisect(rec)
  |> list.flat_map(coordinates.bisect)
  |> set.from_list
  |> should.equal(exp)
}

pub fn search_1_test() {
  let rec = bounds()
  let v = vector.Vec
  let r = rectangle.Rectangle
  let poi = [v(0.0, 0.0), v(10.0, 10.0)]
  let f = fn(r: Rectangle) { poi |> list.filter(rectangle.contains(r, _)) }
  let res = coordinates.search_all(f, rec)
  res |> list.map(fn(a) { a.0 }) |> rectangle_debug.debug_points(poi)
  let exp = [
    #(r(v(0.0, 0.0), v(8.0, 16.0)), v(0.0, 0.0)),
    #(r(v(8.0, 0.0), v(16.0, 16.0)), v(10.0, 10.0)),
  ]

  exp
  |> list.map(fn(a) { a.0 })
  |> rectangle_debug.debug_points(poi)

  should.equal(res |> set.from_list, exp |> set.from_list)
}

fn dbg(r) {
  rectangle_debug.debug_points(r, point_of_interest)
  // rectangle_debug.debug(r)
}

pub fn search_test() {
  let rec = bounds()
  let f = fn(r: Rectangle) {
    point_of_interest |> list.filter(rectangle.contains(r, _))
  }
  let res = coordinates.search_all(f, rec)
  let v = vector.Vec
  let r = rectangle.Rectangle
  let exp = [
    #(r(v(0.0, 0.0), v(1.0, 2.0)), v(0.0, 0.0)),
    #(r(v(1.0, 0.0), v(2.0, 2.0)), v(1.0, 1.0)),
    #(r(v(0.0, 4.0), v(4.0, 8.0)), v(1.0, 6.0)),
    #(r(v(2.0, 0.0), v(4.0, 2.0)), v(2.0, 0.0)),
    #(r(v(2.0, 2.0), v(4.0, 4.0)), v(2.0, 2.0)),
    #(r(v(8.0, 8.0), v(16.0, 16.0)), v(11.0, 14.0)),
    #(r(v(8.0, 0.0), v(16.0, 8.0)), v(14.0, 7.0)),
  ]

  io.println_error("Output:")
  res |> list.map(tuple.fst) |> dbg
  io.println_error("Expected:")
  exp
  |> list.map(tuple.fst)
  |> dbg

  let res = res |> set.from_list
  let exp = exp |> set.from_list

  should.equal(res |> set.map(tuple.fst), exp |> set.map(tuple.fst))
  should.equal(res |> set.map(tuple.snd), exp |> set.map(tuple.snd))
  should.equal(res, exp)
}
