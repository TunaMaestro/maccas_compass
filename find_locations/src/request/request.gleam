import envoy
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/io
import gleam/json
import gleam/result
import gleam/string
import rectangle
import request/parse
import simplifile
import vector

const field_mask_header = "X-Goog-FieldMask"

const field_mask = [
  "places.businessStatus", "places.containingPlaces", "places.displayName",
  "places.formattedAddress", "places.location", "places.pureServiceAreaBusiness",
  "places.shortFormattedAddress", "places.subDestinations", "places.viewport",
]

const text_query = "McDonald's"

const max_results_per_request = 20

const endpoint = "https://places.googleapis.com/v1/places:searchText"

pub fn tests() {
  let r = build_request(aus())
  r
  |> http_raw
}

pub fn query(
  rec: rectangle.Rectangle,
) -> Result(parse.Places, #(json.DecodeError, String)) {
  let json =
    build_request(rec)
    |> http_raw
  // let assert Ok(json) = simplifile.read("./dumps/1.json")
  json
  |> parse.places_from_json
  |> result.map_error(fn(x) { #(x, json) })
}

fn parse() {
  let assert Ok(json) = simplifile.read("./dumps/1.json")
    as "should be able to read /dev/stdin"
  io.println_error(json)
  let assert Ok(k) = parse.places_from_json(json)
    as "should be able to parse json"
  io.debug(k)
}

pub fn build_request(viewport: rectangle.Rectangle) {
  let assert Ok(req) = request.to(endpoint)
  let assert Ok(key) = envoy.get("GOOGLE_API_KEY")
    as "Google API key was not provided in GOOGLE_API_KEY"
  let req =
    req
    |> request.set_method(http.Post)
    |> request.prepend_header(field_mask_header, field_mask |> string.join(","))
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("X-Goog-Api-Key", key)

  let json =
    [
      #("textQuery", json.string(text_query)),
      #(
        "locationRestriction",
        json.object([#("rectangle", serialise_rectangle(viewport))]),
      ),
    ]
    |> json.object

  let body = json.to_string(json)
  req |> request.set_body(body)
}

fn http_raw(r: request.Request(String)) {
  let assert Ok(res) = httpc.send(r)
  res.body
}

fn serialise_rectangle(rectangle: rectangle.Rectangle) {
  [
    #("low", serialise_point(rectangle.low)),
    #("high", serialise_point(rectangle.high)),
  ]
  |> json.object
}

fn serialise_point(p: vector.Vec) {
  [#("latitude", json.float(p.y)), #("longitude", json.float(p.x))]
  |> json.object
}

fn aus() {
  let assert Ok(aus_bound) =
    rectangle.new_raw(
      113.338953078,
      -43.6345972634,
      153.6380696,
      -10.6681857235,
    )
  aus_bound
}
