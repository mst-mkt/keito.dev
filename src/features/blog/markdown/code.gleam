import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option}
import gleam/result
import gleam/string
import lib/highlight
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(info: Option(String), text: String) -> Promise(Element(msg)) {
  let info = option.unwrap(info, "")
  let code = case string.ends_with(text, "\n") {
    True -> string.drop_end(text, 1)
    False -> text
  }
  use lines <- promise.map(highlight.highlight(code, language(info)))
  let pre =
    html.pre([attribute.class("overflow-x-auto"), attribute.tabindex(0)], [
      html.code([], highlight.view(lines)),
    ])

  case title(info) {
    Ok(title) -> html.figure([], [html.figcaption([], [html.text(title)]), pre])
    Error(Nil) -> pre
  }
}

@internal
pub fn language(info: String) -> String {
  case string.split_once(info, " ") {
    Ok(#(language, _)) -> language
    Error(Nil) -> info
  }
}

fn title(info: String) -> Result(String, Nil) {
  use #(_, rest) <- result.try(string.split_once(" " <> info, " title=\""))
  use #(title, _) <- result.map(string.split_once(rest, "\""))

  title
}
