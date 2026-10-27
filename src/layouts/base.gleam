import components/dock
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub const origin = "https://keito.dev"

pub fn canonical(path: String) -> Element(Nil) {
  html.link([attribute.rel("canonical"), attribute.href(origin <> path)])
}

pub fn document(
  title: String,
  left left: List(Element(Nil)),
  content content: List(Element(Nil)),
  right right: List(Element(Nil)),
  dock dock: List(dock.Item(Nil)),
  head head: List(Element(Nil)),
  client_entry client_entry: String,
) -> Element(Nil) {
  page(title, client_entry, head, [
    html.div([attribute.class("flex justify-center gap-x-12 px-6 py-24")], [
      sidebar(left),
      html.main([attribute.class("w-full max-w-2xl min-w-0")], content),
      sidebar(right),
    ]),
    dock.view("Menu", dock),
  ])
}

pub fn shell(
  title: String,
  client_entry: String,
  body: List(Element(Nil)),
) -> Element(Nil) {
  page(title, client_entry, [], body)
}

fn page(
  title: String,
  client_entry: String,
  head: List(Element(Nil)),
  body: List(Element(Nil)),
) -> Element(Nil) {
  html.html([attribute.lang("en")], [
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
        attribute.href("https://serenity.keito.dev/%F0%9F%A7%B6/svg?square"),
      ]),
      html.link([
        attribute.rel("icon"),
        attribute.href("https://serenity.keito.dev/%F0%9F%A7%B6/ico?square"),
        attribute.attribute("sizes", "any"),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/entry/style.css"),
      ]),
      html.link([
        attribute.rel("webmention"),
        attribute.href("https://webmention.io/keito.dev/webmention"),
      ]),
      html.script([attribute.type_("module"), attribute.src(client_entry)], ""),
      ..head
    ]),
    html.body([], body),
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
