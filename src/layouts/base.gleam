import components/dock
import lib/ogp
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub const origin = "https://keito.dev"

pub const og_image = origin <> "/ogp.png"

pub fn canonical(path: String) -> Element(Nil) {
  html.link([attribute.rel("canonical"), attribute.href(origin <> path)])
}

pub fn document(
  title: String,
  og_image og_image: String,
  left left: List(Element(Nil)),
  content content: List(Element(Nil)),
  right right: List(Element(Nil)),
  dock dock: List(dock.Item(Nil)),
  head head: List(Element(Nil)),
  client_entry client_entry: String,
) -> Element(Nil) {
  page(title, og_image, [client_script(client_entry, []), ..head], [
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
  head head: List(Element(Nil)),
  body body: List(Element(Nil)),
) -> Element(Nil) {
  let script =
    client_script(client_entry, [attribute.attribute("blocking", "render")])

  page(title, og_image, [script, ..head], body)
}

fn client_script(
  client_entry: String,
  attributes: List(attribute.Attribute(Nil)),
) -> Element(Nil) {
  html.script(
    [attribute.type_("module"), attribute.src(client_entry), ..attributes],
    "",
  )
}

fn page(
  title: String,
  og_image: String,
  head: List(Element(Nil)),
  body: List(Element(Nil)),
) -> Element(Nil) {
  let document_title = case title {
    "" -> "keito.dev"
    _ -> title <> " | keito.dev"
  }
  let og_title = case title {
    "" -> "keito.dev"
    _ -> title
  }

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
      html.title([], document_title),
      ogp.property("og:title", og_title),
      ogp.property("og:site_name", "keito.dev"),
      ogp.property("og:image", og_image),
      ogp.property("og:image:width", "2400"),
      ogp.property("og:image:height", "1260"),
      html.meta([
        attribute.name("twitter:card"),
        attribute.content("summary_large_image"),
      ]),
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
