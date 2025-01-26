import gleam/list
import rectangle.{type Rectangle, Rectangle}
import vector.{type Vec, Vec, add}

/// +----------+
/// |          |
/// |          |
/// |          |
/// |          |
/// |          |
/// +----------+
///
/// ->
///
/// +-----F-----G
/// |     |     |
/// |     |     |
/// C-----D-----E
/// |     |     |
/// |     |     |
/// A-----B-----+
/// Returns the rectangles: AD BE CF DG in arbitrary order
pub fn quadrisect(rectangle rec: Rectangle) -> List(Rectangle) {
  // implemented to return AD BE CF DG
  let i = Vec(rec.high.x -. rec.high.x /. 2.0, 0.0)
  let j = Vec(0.0, rec.high.y -. rec.high.y /. 2.0)

  let rectangle.Rectangle(a, g) = rec

  let b = a |> add(i)
  let c = a |> add(j)
  let d = a |> add(i) |> add(j)
  let e = d |> add(i)
  let f = d |> add(j)

  [
    Rectangle(low: a, high: d),
    Rectangle(low: b, high: e),
    Rectangle(low: c, high: f),
    Rectangle(low: d, high: g),
  ]
}

///
/// +---C---D
/// |   |   +
/// A---B---+
///
fn bisect_horizontal(rectangle rec: Rectangle) -> List(Rectangle) {
  let rectangle.Rectangle(a, d) = rec
  let i = Vec({ d.x -. a.x } /. 2.0, 0.0)
  let j = Vec(0.0, d.y -. a.y)

  let a = rec.low
  let b = a |> add(i)
  let c = b |> add(j)

  [Rectangle(a, c), Rectangle(b, d)]
}

///
/// +---D
/// |   |
/// B---C
/// |   |
/// A---+
///
fn bisect_vertical(rectangle rec: Rectangle) -> List(Rectangle) {
  let rectangle.Rectangle(a, d) = rec
  let i = Vec(rec.high.x -. rec.low.x, 0.0)
  let j = Vec(0.0, { d.y -. a.y } /. 2.0)

  let a = rec.low
  let b = a |> add(j)
  let c = b |> add(i)

  [Rectangle(a, c), Rectangle(b, d)]
}

pub fn bisect(rectangle r: Rectangle) -> List(Rectangle) {
  case r.high.x -. r.low.x >=. r.high.y -. r.low.y {
    True -> bisect_horizontal(r)
    False -> bisect_vertical(r)
  }
}

pub fn search_all(
  search_fn f: fn(Rectangle) -> List(a),
  start_bound bound: Rectangle,
) -> List(#(Rectangle, a)) {
  let contained = f(bound)
  case contained {
    [] -> []
    [x] -> [#(bound, x)]
    _ -> bisect(bound) |> list.map(search_all(f, _)) |> list.flatten
  }
}
