import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/option

pub type Location {
  Location(latitude: Float, longitude: Float)
}

pub type Viewport {
  Viewport(low: Location, high: Location)
}

pub type DisplayName {
  DisplayName(text: String, language_code: String)
}

pub type ContainingPlace {
  ContainingPlace(name: String, id: String)
}

pub type Place {
  Place(
    formatted_address: String,
    location: Location,
    viewport: Viewport,
    business_status: String,
    display_name: DisplayName,
    short_formatted_address: String,
    // containing_places: List(ContainingPlace),
  )
}

pub type Places {
  Places(places: List(Place))
}

pub fn places_from_json(json_string: String) -> Result(Places, json.DecodeError) {
  // Location decoder
  let location_decoder = {
    use latitude <- decode.field("latitude", decode.float)
    use longitude <- decode.field("longitude", decode.float)
    decode.success(Location(latitude:, longitude:))
  }

  // Viewport decoder
  let viewport_decoder = {
    use low <- decode.field("low", location_decoder)
    use high <- decode.field("high", location_decoder)
    decode.success(Viewport(low:, high:))
  }

  // DisplayName decoder
  let display_name_decoder = {
    use text <- decode.field("text", decode.string)
    use language_code <- decode.field("languageCode", decode.string)
    decode.success(DisplayName(text:, language_code:))
  }

  // ContainingPlace decoder
  let containing_place_decoder = {
    use name <- decode.field("name", decode.string)
    use id <- decode.field("id", decode.string)
    decode.success(ContainingPlace(name:, id:))
  }

  // Place decoder
  let place_decoder = {
    use formatted_address <- decode.field("formattedAddress", decode.string)
    use location <- decode.field("location", location_decoder)
    use viewport <- decode.field("viewport", viewport_decoder)
    use business_status <- decode.optional_field(
      "businessStatus",
      "UNKNOWN",
      decode.string,
    )
    use display_name <- decode.field("displayName", display_name_decoder)
    use short_formatted_address <- decode.field(
      "shortFormattedAddress",
      decode.string,
    )
    // use containing_places <- decode.field(
    //   "containingPlaces",
    //   decode.list(containing_place_decoder),
    // )
    decode.success(Place(
      formatted_address:,
      location:,
      viewport:,
      business_status:,
      display_name:,
      short_formatted_address:,
      // containing_places:,
    ))
  }

  // Places decoder
  let places_decoder = {
    use places <- decode.optional_field(
      "places",
      [],
      decode.list(place_decoder),
    )
    decode.success(Places(places:))
  }

  json.parse(from: json_string, using: places_decoder)
}
// fn f() {
//   Error(
//     UnableToDecode([
//       DecodeError("Field", "Nothing", ["places", "0", "formatted_address"]),
//       DecodeError("Field", "Nothing", ["places", "0", "business_status"]),
//       DecodeError("Field", "Nothing", ["places", "0", "display_name"]),
//       DecodeError("Field", "Nothing", ["places", "0", "short_formatted_address"]),
//       DecodeError("Field", "Nothing", ["places", "0", "containing_places"]),
//     ]),
//   )
// }
