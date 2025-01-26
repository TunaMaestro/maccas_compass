import gleam/list
import gleam/string

pub fn zip(a: List(List(a)), b: List(List(b))) -> List(List(#(a, b))) {
  list.zip(a, b)
  |> list.map(uncurry(list.zip))
}

pub fn map(a, f) {
  a
  |> list.map(list.map(_, f))
}

pub fn index_map(l, f) {
  l
  |> list.index_map(fn(row, y) {
    row
    |> list.index_map(fn(c, x) { f(c, #(x, y)) })
  })
}

pub fn join(ll, inner inner: String, outer outer: String) -> String {
  ll
  |> list.map(string.join(_, inner))
  |> string.join(outer)
}

fn uncurry(f) {
  fn(x) {
    let #(a, b) = x
    f(a, b)
  }
}
