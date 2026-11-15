import gleam/float
import gleam/http/request.{type Request}
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn preferred(
  req: Request(body),
  types: List(String),
) -> Result(String, Nil) {
  let ranges =
    request.get_header(req, "accept")
    |> result.unwrap("*/*")
    |> parse

  types
  |> list.map(fn(media_type) { #(media_type, quality(ranges, media_type)) })
  |> list.filter(fn(candidate) { candidate.1 >. 0.0 })
  |> list.fold(Error(Nil), fn(best, candidate) {
    case best {
      Ok(#(_, best_quality)) if best_quality >=. candidate.1 -> best
      _ -> Ok(candidate)
    }
  })
  |> result.map(fn(best) { best.0 })
}

fn parse(header: String) -> List(#(String, Float)) {
  use range <- list.map(string.split(header, ","))
  let assert [media_range, ..parameters] = string.split(range, ";")

  #(string.lowercase(string.trim(media_range)), q_value(parameters))
}

fn q_value(parameters: List(String)) -> Float {
  list.find_map(parameters, fn(parameter) {
    case string.trim(parameter) {
      "q=" <> value ->
        float.parse(value)
        |> result.lazy_or(fn() { int.parse(value) |> result.map(int.to_float) })
      _ -> Error(Nil)
    }
  })
  |> result.unwrap(1.0)
}

fn quality(ranges: List(#(String, Float)), media_type: String) -> Float {
  let #(kind, _) =
    string.split_once(media_type, "/") |> result.unwrap(#(media_type, ""))

  [media_type, kind <> "/*", "*/*"]
  |> list.find_map(fn(range) { list.key_find(ranges, range) })
  |> result.unwrap(0.0)
}
