import features/blog/post.{type Post}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import layouts/base
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub fn link() -> Element(msg) {
  html.link([
    attribute.rel("alternate"),
    attribute.type_("application/atom+xml"),
    attribute.title("keito.dev"),
    attribute.href(post.feed_path),
  ])
}

pub fn atom(posts: List(Post)) -> String {
  let url = base.origin <> post.list_path
  let updated = list.map(posts, last_updated) |> list.max(string.compare)
  let feed =
    node("feed", [], [
      text_node("title", "keito.dev"),
      text_node("id", url),
      node("link", [attribute.href(url)], []),
      node(
        "link",
        [attribute.rel("self"), attribute.href(base.origin <> post.feed_path)],
        [],
      ),
      case updated {
        Ok(updated) -> text_node("updated", timestamp(updated))
        Error(Nil) -> element.none()
      },
      node("author", [], [
        text_node("name", "mst-mkt"),
        text_node("uri", base.origin),
      ]),
      ..list.map(posts, entry_node)
    ])

  "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" <> element.to_string(feed)
}

fn entry_node(entry: Post) -> Element(msg) {
  let url = base.origin <> post.page_path(entry.slug)

  node("entry", [], [
    text_node("title", entry.title),
    text_node("id", url),
    node("link", [attribute.href(url)], []),
    text_node("published", timestamp(entry.published_at)),
    text_node("updated", timestamp(last_updated(entry))),
    case entry.description {
      Some(description) -> text_node("summary", description)
      None -> element.none()
    },
  ])
}

fn last_updated(entry: Post) -> String {
  option.unwrap(entry.updated_at, entry.published_at)
}

fn timestamp(date: String) -> String {
  date <> "T00:00:00+09:00"
}

fn node(
  tag: String,
  attributes: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element.namespaced("http://www.w3.org/2005/Atom", tag, attributes, children)
}

fn text_node(tag: String, text: String) -> Element(msg) {
  node(tag, [], [element.text(text)])
}
