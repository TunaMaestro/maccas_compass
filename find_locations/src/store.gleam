import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import request/parse
import sqlight as sql
import sqlight

const uri = "file:locations.sqlite3"

fn place_values(place: parse.Place) -> List(sqlight.Value) {
  [
    place.formatted_address |> sql.text,
    place.location.latitude |> sql.float,
    place.location.longitude |> sql.float,
    place.viewport.low.latitude |> sql.float,
    place.viewport.low.longitude |> sql.float,
    place.viewport.high.latitude |> sql.float,
    place.viewport.high.longitude |> sql.float,
    place.business_status |> sql.text,
    place.display_name.text |> sql.text,
    place.display_name.language_code |> sql.text,
    place.short_formatted_address |> sql.text,
  ]
}

fn params(len) {
  list.repeat("?", len) |> string.join(", ")
}

pub fn main() {
  use conn <- sqlight.with_connection(":memory:")
  let cat_decoder = {
    use name <- decode.field(0, decode.string)
    use age <- decode.field(1, decode.int)
    decode.success(#(name, age))
  }

  let assert Ok(_) =
    sqlight.exec("create table cats (name text, age int);", conn)
  let sql =
    "
  insert into cats (name, age) values 
  (?, ?),
  (?, ?),
  (?, ?);
  "
  let assert Ok(i) =
    sqlight.query(
      sql,
      conn,
      [
        sql.text("Nubi"),
        sql.int(4),
        sql.text("Ginny"),
        sql.int(6),
        sql.text("AAA"),
        sql.int(50),
      ],
      decode.int,
    )

  io.println_error("Inserted i = ")
  io.debug(i)

  let sql =
    "
  select name, age from cats
  where age < ?
  "
  let assert Ok([#("Nubi", 4), #("Ginny", 6)]) =
    sqlight.query(sql, on: conn, with: [sqlight.int(7)], expecting: cat_decoder)
}

pub fn store_all(places: List(parse.Place)) -> Result(Int, Nil) {
  let assert Ok(conn) = sqlight.open(uri)
  let assert Ok(_) = create(conn)
  store(places, conn)
}

fn store(
  places: List(parse.Place),
  conn: sqlight.Connection,
) -> Result(Int, Nil) {
  case places {
    [] -> Ok(0)
    [_, ..] -> {
      let ps = "(" <> params(11) <> ")"
      let stmt =
        "
    INSERT INTO places
      (formatted_address, location_latitude,
        location_longitude, viewport_low_latitude, viewport_low_longitude,
        viewport_high_latitude, viewport_high_longitude, business_status,
        display_name_text, display_name_language_code, short_formatted_address)
      VALUES
  "
      let param_rows =
        list.repeat(ps, list.length(places)) |> string.join(",\n")
      let sql = stmt <> param_rows <> "
    RETURNING id
  "
      // io.println(sql)
      let values = places |> list.flat_map(place_values)
      // io.debug(values)
      // io.debug(values |> list.length)

      let tuple_int_decoder = {
        use i <- decode.field(0, decode.int)
        decode.success(i)
      }

      let q_res =
        sqlight.query(sql, on: conn, with: values, expecting: tuple_int_decoder)
        |> result.map_error(fn(err) {
          io.debug(err)
          Nil
        })
      use ids <- result.then(q_res)
      ids |> list.max(int.compare)
    }
  }
}

pub fn create(with con: sqlight.Connection) {
  sqlight.exec(
    "
  CREATE TABLE IF NOT EXISTS places (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    formatted_address TEXT NOT NULL,
    location_latitude REAL NOT NULL,
    location_longitude REAL NOT NULL,
    viewport_low_latitude REAL NOT NULL,
    viewport_low_longitude REAL NOT NULL,
    viewport_high_latitude REAL NOT NULL,
    viewport_high_longitude REAL NOT NULL,
    business_status TEXT NOT NULL,
    display_name_text TEXT NOT NULL,
    display_name_language_code TEXT NOT NULL,
    short_formatted_address TEXT NOT NULL
  );  ",
    con,
  )
}
