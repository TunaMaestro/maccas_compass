import gleam/float
import gleam/order
import vector.{type Vec, Vec}

/// use the constructor new_rectangle
/// low < high must be upheld over x and y
pub type Rectangle {
  Rectangle(low: Vec, high: Vec)
}

pub fn new(low: Vec, high: Vec) -> Result(Rectangle, Nil) {
  case float.compare(low.x, high.x), float.compare(low.y, high.y) {
    order.Lt, order.Lt -> Ok(Rectangle(low:, high:))
    _, _ -> Error(Nil)
  }
}

pub fn new_raw(low_x a, low_y b, high_x c, high_y d) -> Result(Rectangle, Nil) {
  new(Vec(a, b), Vec(c, d))
}

pub fn contains(in rec: Rectangle, point point: Vec) -> Bool {
  rec.low.x <=. point.x
  && rec.low.y <=. point.y
  && point.x <. rec.high.x
  && point.y <. rec.high.y
}
