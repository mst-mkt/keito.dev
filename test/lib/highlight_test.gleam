import gleam/json
import lib/highlight.{Token}
import lustre/element
import lustre/element/html

pub fn decoder_test() {
  let body =
    json.preprocessed_array([
      json.preprocessed_array([
        json.object([
          #("content", json.string("# heading")),
          #(
            "htmlStyle",
            json.object([
              #("color", json.string("light-dark(#005CC5, #79B8FF)")),
              #("--shiki-light", json.string("#005CC5")),
              #("--shiki-dark", json.string("#79B8FF")),
              #("--shiki-light-font-weight", json.string("bold")),
              #("--shiki-dark-font-weight", json.string("bold")),
            ]),
          ),
        ]),
      ]),
    ])
    |> json.to_string

  let result = json.parse(body, highlight.decoder())

  assert result
    == Ok([
      [
        Token("# heading", [
          #("color", "light-dark(#005CC5, #79B8FF)"),
          #("font-weight", "bold"),
        ]),
      ],
    ])
}

pub fn view_test() {
  let lines = [
    [
      Token("const", [#("color", "light-dark(#D73A49, #F97583)")]),
      Token(" a", []),
    ],
    [Token("b", [])],
  ]

  let rendered = html.code([], highlight.view(lines)) |> element.to_string

  assert rendered
    == "<code><span style=\"color:light-dark(#D73A49, #F97583);\">const</span> a\nb</code>"
}

pub fn plain_test() {
  let code = "a\n\nb"

  let lines = highlight.plain(code)

  assert lines == [[Token("a", [])], [Token("", [])], [Token("b", [])]]
}
