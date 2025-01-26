import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}

pub fn main() {
  io.println("Hello from find_locations!")
}

pub fn sequence_list_option(l: List(option.Option(a))) -> option.Option(List(a)) {
  list.fold_right(l, Some([]), fn(a, l) {
    a
    |> option.then(fn(acc) {
      l
      |> option.map(list.prepend(acc, _))
    })
  })
}
