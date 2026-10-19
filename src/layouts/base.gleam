import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn document(
  title: String,
  content: List(Element(Nil)),
  scripts: List(String),
) -> Element(Nil) {
  html.html([attribute.lang("ja")], [
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.title([], title <> " | keito.dev"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/entry/style.css"),
      ]),
      ..list.map(scripts, fn(src) {
        html.script([attribute.type_("module"), attribute.src(src)], "")
      })
    ]),
    html.body([], [html.main([], content)]),
  ])
}
