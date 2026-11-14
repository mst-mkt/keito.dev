import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Token {
  Token(content: String, styles: List(#(String, String)))
}

type Highlighter

pub fn highlight(code: String, lang: String) -> Promise(List(List(Token))) {
  get()
  |> promise.map(fn(highlighter) {
    case is_loaded(highlighter, lang) {
      True ->
        decode.run(tokens(highlighter, code, lang), decoder())
        |> result.lazy_unwrap(fn() { plain(code) })
      False -> plain(code)
    }
  })
  |> promise.rescue(fn(_) { plain(code) })
}

@internal
pub fn plain(code: String) -> List(List(Token)) {
  string.split(code, "\n") |> list.map(fn(line) { [Token(line, [])] })
}

pub fn view(lines: List(List(Token))) -> List(Element(msg)) {
  lines
  |> list.map(list.map(_, token_view))
  |> list.intersperse([html.text("\n")])
  |> list.flatten
}

fn token_view(token: Token) -> Element(msg) {
  case token.styles {
    [] -> html.text(token.content)
    styles -> html.span([attribute.styles(styles)], [html.text(token.content)])
  }
}

const properties = [
  #("color", "color"),
  #("--shiki-light-font-style", "font-style"),
  #("--shiki-light-font-weight", "font-weight"),
  #("--shiki-light-text-decoration", "text-decoration"),
]

@internal
pub fn decoder() -> Decoder(List(List(Token))) {
  decode.list(decode.list(token_decoder()))
}

fn token_decoder() -> Decoder(Token) {
  use content <- decode.field("content", decode.string)
  use style <- decode.field(
    "htmlStyle",
    decode.dict(decode.string, decode.string),
  )
  let styles =
    list.filter_map(properties, fn(property) {
      dict.get(style, property.0)
      |> result.map(fn(value) { #(property.1, value) })
    })

  decode.success(Token(content:, styles:))
}

@external(javascript, "./highlight.ffi.ts", "get")
fn get() -> Promise(Highlighter)

@external(javascript, "./highlight.ffi.ts", "isLoaded")
fn is_loaded(highlighter: Highlighter, lang: String) -> Bool

@external(javascript, "./highlight.ffi.ts", "tokens")
fn tokens(highlighter: Highlighter, code: String, lang: String) -> Dynamic
