import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import glearray
import list2
import vector.{type Vec, Vec}

import rectangle.{type Rectangle, Rectangle}

fn index_point(point: Vec, rec: List(Rectangle)) -> Option(Int) {
  rec
  |> list.index_map(fn(a, i) { #(rectangle.contains(a, point), i) })
  |> list.find(fn(e) { e.0 })
  |> result.map(fn(e) { e.1 })
  |> option.from_result
}

fn index(rectangles rs: List(Rectangle)) -> List(List(Option(Int))) {
  case
    rs
    |> list.map(fn(x) { x.high })
    |> list.reduce(fn(a, b) { vector.map2(a, b, float.max) })
  {
    Error(_) -> []
    Ok(dim) -> {
      list.range(0, float.round(dim.y) + 0)
      |> list.map(fn(y) {
        list.range(0, float.round(dim.x) + 0)
        |> list.map(fn(x) {
          index_point(Vec(int.to_float(x), int.to_float(y)), rs)
        })
      })
    }
  }
}

fn display_index(rectangles rs: List(Rectangle)) -> List(List(String)) {
  let grid = index(rs)
  grid
  |> list.map(fn(row) {
    row
    |> list.map(fn(a) {
      option.map(a, int.to_string)
      |> option.unwrap("")
      |> string.pad_start(1, " ")
    })
  })
}

fn display_point(
  colours: glearray.Array(Int),
  rectangle_index: Option(Int),
  point: Bool,
) -> String {
  let colouring = {
    rectangle_index
    |> option.to_result(Nil)
    |> result.then(int.modulo(_, glearray.length(colours)))
    |> result.then(glearray.get(_, in: colours))
    |> result.map(ansi_colour(_, Background))
    |> result.unwrap("\u{1b}[1m\u{1b}[31m")
  }
  let p = case point {
    True -> "<>"
    False -> "  "
  }
  colouring <> p <> ansi_reset
}

fn display_points(rectangle rs: List(Rectangle), points points: List(Vec)) {
  let colours = glearray.from_list(colours)
  let indicies = index(rs)
  let ps = points |> list.map(fn(v) { #(float.round(v.x), float.round(v.y)) })
  indicies
  |> list2.index_map(fn(rec, p) {
    display_point(colours, rec, list.contains(ps, p))
  })
}

pub fn debug(rectangles rs: List(Rectangle)) -> List(Rectangle) {
  io.println_error(display_index(rs) |> list2.join("", "\n"))
  rs
}

pub fn debug_points(
  rectangles rs: List(Rectangle),
  points points: List(Vec),
) -> List(Rectangle) {
  io.println_error(display_points(rs, points) |> border)
  rs
}

const colours = [
  0x1446a0, 0xdb3069, 0x3c3c3b, 0x7b3e19, 0xb28b84, 0x7d83ff, 0x590925, 0xc33149,
  0xa22522, 0x473198, 0x4a0d67,
]

fn split_colour(colour: Int) -> #(Int, Int, Int) {
  #(
    int.bitwise_and(int.bitwise_shift_right(colour, 16), 0xFF),
    int.bitwise_and(int.bitwise_shift_right(colour, 8), 0xFF),
    int.bitwise_and(colour, 0xFF),
  )
}

const ansi_reset = "\u{1b}[m"

fn border(cells: List(List(String))) {
  let cells =
    cells
    |> list.reverse
  case cells {
    [] -> []
    [first, ..] -> {
      let rows =
        list.map(cells, string.join(_, ""))
        |> list.map(fn(s) { "█" <> s <> "█" })
      rows |> list.map(string.length)
      let width = list.length(first)
      let top = string.repeat("▄▄", width + 1)
      let bottom = string.repeat("▀▀", width + 1)
      [top, ..rows]
      |> list.append([bottom])
    }
  }
  |> string.join("\n")
}

/// ESC[38;2;⟨r⟩;⟨g⟩;⟨b⟩ m Select RGB foreground color
fn ansi_colour(colour: Int, apply_to t: AnsiColour) {
  let fg = case t {
    Foreground -> "38"
    Background -> "48"
  }
  let #(r, g, b) = split_colour(colour)
  let r = int.to_string(r)
  let g = int.to_string(g)
  let b = int.to_string(b)
  "\u{1b}[" <> fg <> ";2;" <> r <> ";" <> g <> ";" <> b <> "m"
}

type AnsiColour {
  Foreground
  Background
}
