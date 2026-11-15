import features/blog/markdown/inline
import gleam/dict.{type Dict}
import gleam/int
import gleam/regexp
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import mork/document.{type Document, type Inline}

pub type Ids =
  Dict(String, Int)

pub fn view(
  document: Document,
  level: Int,
  id: String,
  inlines: List(Inline),
) -> Element(msg) {
  element.element(
    "h" <> int.to_string(level),
    [attribute.id(id)],
    inline.view(document, inlines),
  )
}

pub fn id(ids: Ids, inlines: List(Inline)) -> #(Ids, String) {
  let id = slug(inline.plain_text(inlines))

  case dict.get(ids, id) {
    Ok(count) -> #(
      dict.insert(ids, id, count + 1),
      id <> "-" <> int.to_string(count),
    )
    Error(Nil) -> #(dict.insert(ids, id, 1), id)
  }
}

@internal
pub fn slug(text: String) -> String {
  let assert Ok(symbols) = regexp.from_string("[^\\p{L}\\p{M}\\p{N}\\p{Pc} -]")

  text
  |> string.trim
  |> string.lowercase
  |> regexp.replace(symbols, _, "")
  |> string.replace(" ", "-")
}
