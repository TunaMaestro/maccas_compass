//// Source code lifted from https://hex.pm/packages/glector
//// I wanted to add more functions

import gleam/float
import gleam/result

pub type Vec {
  Vec(x: Float, y: Float)
}

/// The zero vector `(0, 0)`.
pub const zero = Vec(0.0, 0.0)

/// Adds vector `a` to vector `b`.
/// ```gleam
/// add(Vec(1.0, 2.0), Vec(3.0, 4.0)) // -> Vec(4.0, 6.0)
/// ```
pub fn add(a: Vec, b: Vec) {
  Vec(a.x +. b.x, a.y +. b.y)
}

/// Gets the value of the z component of the cross product of vectors `a` and `b`.
/// 
/// Note: the 2D vectors `a` and `b` are treated as 3D vectors where their z component is zero.
/// ```gleam
/// cross(Vec(1.0, 2.0), Vec(3.0, 4.0)) // -> -2.0
/// ```
pub fn cross(a: Vec, b: Vec) {
  a.x *. b.y -. a.y *. b.x
}

/// Gets the dot product of vectors `a` and `b`.
/// ```gleam
/// dot(Vec(-6.0, 8.0), Vec(5.0, 12.0)) // -> 66.0
/// ```
pub fn dot(a: Vec, b: Vec) {
  a.x *. b.x +. a.y *. b.y
}

/// Flips or reverses a vector's direction.
/// ```gleam
/// invert(Vec(1.0, 2.0)) // -> Vec(-1.0, -2.0)
/// ```
pub fn invert(v: Vec) {
  Vec(v.x *. -1.0, v.y *. -1.0)
}

/// Gets the length of a vector.
/// 
/// Note: it's faster to get a vector's square length than its actual length.
/// So for certain use cases like comparing the length of 2 vectors, I recommend using `length_sq` instead.
/// ```gleam
/// length(Vec(8.0, -6.0)) // -> 10.0
/// ```
pub fn length(v: Vec) {
  v
  |> length_sq
  |> float.square_root()
  |> result.unwrap(0.0)
}

/// Gets the square length of a vector.
/// ```gleam
/// length_sq(Vec(8.0, -6.0)) // -> 100.0
/// ```
pub fn length_sq(v: Vec) {
  let a = float.absolute_value(v.x)
  let b = float.absolute_value(v.y)
  a *. a +. b *. b
}

/// Gets the linear interpolation between two vectors.
/// ```gleam
/// lerp(Vec(10.0, 0.0), Vec(0.0, -10.0), 0.5) // -> Vec(5.0, -5.0)
/// ```
pub fn lerp(a: Vec, b: Vec, t: Float) {
  let x = a.x +. t *. { b.x -. a.x }
  let y = a.y +. t *. { b.y -. a.y }
  Vec(x: x, y: y)
}

/// Multiplies the x and y components of vectors `a` and `b`.
/// ```gleam
/// multiply(Vec(1.0, 2.0), Vec(3.0, 4.0)) // -> Vec(3.0, 8.0)
/// ```
pub fn multiply(a: Vec, b: Vec) {
  Vec(a.x *. b.x, a.y *. b.y)
}

/// Gets the normal of a vector representing an edge.
/// The winding direction is anti-clockwise.
/// ```gleam
/// normal(Vec(-123.0, 0.0)) // -> Vec(0.0, -1.0)
/// ```
pub fn normal(v: Vec) {
  v
  |> swap()
  |> multiply(Vec(-1.0, 1.0))
  |> normalise()
}

/// Scales a vector such that its length is `1.0`.
/// ```gleam
/// normalize(Vec(100.0, 0.0)) // -> Vec(1.0, 0.0)
/// ```
pub fn normalise(v: Vec) {
  let d = length(v)
  scale(v, 1.0 /. d)
}

/// Multiplies both components of vector `v` by `scalar`.
/// ```gleam
/// scale(Vec(1.0, 2.0), 2.0) // -> Vec(2.0, 4.0)
/// ```
pub fn scale(v: Vec, scalar: Float) {
  Vec(v.x *. scalar, v.y *. scalar)
}

/// Subtracts vector `b` from vector `a`.
/// ```gleam
/// subtract(Vec(1.0, 2.0), Vec(3.0, 4.0)) // -> Vec(-2.0, -2.0)
/// ```
pub fn subtract(a: Vec, b: Vec) {
  Vec(a.x -. b.x, a.y -. b.y)
}

/// Swaps the x and y components of a vector around.
/// ```gleam
/// swap(Vec(1.0, -2.0)) // -> Vec(-2.0, 1.0)
/// ```
pub fn swap(v: Vec) {
  Vec(v.y, v.x)
}

/// Element-wise map over a unary function
/// ```gleam
/// map(Vec(1.0, -2.0), abs) // -> Vec(1.0, 2.0)
/// ```
pub fn map(a: Vec, f) {
  Vec(f(a.x), f(a.y))
}

/// Element-wise map over a binary function
/// ```gleam
/// map(Vec(1.0, -2.0), Vec(-2.0, 8.0), max) // -> Vec(1.0, 8.0)
/// ```
pub fn map2(a: Vec, b: Vec, f) {
  Vec(f(a.x, b.x), f(a.y, b.y))
}
