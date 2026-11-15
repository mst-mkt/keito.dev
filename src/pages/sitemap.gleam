import features/blog/post.{type Post}
import features/blog/store
import features/links/link
import features/uuid
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}
import hinoto/body.{type Body}
import layouts/base
import lustre/element.{type Element}
import server/context.{type Context}
import server/middleware
import server/respond

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use posts <- promise.map(store.list(context))

  case posts {
    Ok(posts) -> respond.xml(200, xml(posts))
    Error(Nil) -> respond.text(503, "Service Unavailable")
  }
}

pub fn xml(posts: List(Post)) -> String {
  let page_urls =
    ["/", post.list_path, link.list_path, uuid.page_path]
    |> list.map(url_node(_, None))
  let post_urls =
    list.map(posts, fn(entry) {
      url_node(post.page_path(entry.slug), Some(post.last_updated(entry)))
    })
  let urlset = node("urlset", list.append(page_urls, post_urls))

  "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" <> element.to_string(urlset)
}

fn url_node(path: String, lastmod: Option(String)) -> Element(msg) {
  node("url", [
    text_node("loc", base.origin <> path),
    case lastmod {
      Some(lastmod) -> text_node("lastmod", lastmod)
      None -> element.none()
    },
  ])
}

fn node(tag: String, children: List(Element(msg))) -> Element(msg) {
  element.namespaced(
    "http://www.sitemaps.org/schemas/sitemap/0.9",
    tag,
    [],
    children,
  )
}

fn text_node(tag: String, text: String) -> Element(msg) {
  node(tag, [element.text(text)])
}
