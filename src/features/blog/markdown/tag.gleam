import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/string
import lib/html_entity

pub fn parse(raw: String) -> Result(#(String, List(#(String, String))), Nil) {
  let assert Ok(tag) =
    regexp.from_string(
      "^<([A-Za-z][A-Za-z0-9]*)(?:\\s+[A-Za-z][\\w-]*=\"[^\"]*\")*\\s*/?>$",
    )
  let assert Ok(attribute) =
    regexp.from_string("([A-Za-z][\\w-]*)=(\"[^\"]*\")")

  case regexp.scan(tag, raw) {
    [regexp.Match(submatches: [Some(name)], ..)] -> {
      let attributes =
        regexp.scan(attribute, raw)
        |> list.filter_map(fn(match) {
          case match.submatches {
            [Some(key), Some(quoted)] -> Ok(#(key, unquote(quoted)))
            _ -> Error(Nil)
          }
        })

      Ok(#(name, attributes))
    }
    _ -> Error(Nil)
  }
}

fn unquote(quoted: String) -> String {
  quoted
  |> string.drop_start(1)
  |> string.drop_end(1)
  |> html_entity.decode
}
