import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn document(
  title: String,
  left left: List(Element(Nil)),
  content content: List(Element(Nil)),
  right right: List(Element(Nil)),
  scripts scripts: List(String),
) -> Element(Nil) {
  html.html([attribute.lang("ja")], [
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.meta([
        attribute.name("color-scheme"),
        attribute.content("light dark"),
      ]),
      html.title([], title <> " | keito.dev"),
      html.link([
        attribute.rel("icon"),
        attribute.type_("image/svg+xml"),
        attribute.href("https://serenity.keito.dev/%F0%9F%A7%B6/svg"),
      ]),
      html.link([
        attribute.rel("icon"),
        attribute.href("https://serenity.keito.dev/%F0%9F%A7%B6/ico"),
        attribute.attribute("sizes", "any"),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/entry/style.css"),
      ]),
      ..list.map(scripts, fn(src) {
        html.script([attribute.type_("module"), attribute.src(src)], "")
      })
    ]),
    html.body([], [
      html.div([attribute.class("flex justify-center gap-x-6 px-6 py-24")], [
        sidebar(left),
        html.main([attribute.class("w-full max-w-2xl min-w-0")], content),
        sidebar(right),
      ]),
    ]),
  ])
}

fn sidebar(content: List(Element(Nil))) -> Element(Nil) {
  html.aside(
    [
      attribute.class(
        "sticky top-24 hidden w-3xs shrink-0 self-start empty:invisible xl:block",
      ),
    ],
    content,
  )
}
