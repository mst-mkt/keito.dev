import gleam/list
import gleam/string

pub fn document(blocks: List(String)) -> String {
  string.join(blocks, "\n\n") <> "\n"
}

pub fn paragraph(lines: List(String)) -> String {
  string.join(lines, "\n")
}

pub fn list(items: List(String)) -> String {
  items
  |> list.map(fn(item) { "- " <> item })
  |> string.join("\n")
}

pub fn link(text: String, url: String) -> String {
  "[" <> escape(text) <> "](" <> url <> ")"
}

fn escape(text: String) -> String {
  text
  |> string.replace("\\", "\\\\")
  |> string.replace("[", "\\[")
  |> string.replace("]", "\\]")
}
