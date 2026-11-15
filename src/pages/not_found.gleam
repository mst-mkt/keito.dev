import features/blog/post
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import layouts/base
import lib/md
import lustre/element.{type Element}
import lustre/element/html
import pages/sitemap
import server/context.{type Context}
import server/format.{Html, Markdown, Terminal}
import server/respond

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use format <- format.negotiate(req)

  promise.resolve(case format {
    Markdown -> respond.markdown(404, markdown_view())
    Terminal -> respond.text(404, "Not Found")
    Html -> respond.html(404, view(context))
  })
}

fn markdown_view() -> String {
  md.document([
    "# Not Found",
    "The page you requested does not exist.",
    md.list([
      md.link("Home", base.origin <> "/"),
      md.link("Blog", base.origin <> post.list_path),
      md.link("Sitemap", base.origin <> sitemap.path),
    ]),
  ])
}

fn view(context: Context) -> Element(Nil) {
  base.document(
    "Not Found",
    left: [],
    content: [html.h1([], [html.text("Not Found")])],
    right: [],
    dock: [],
    head: [],
    client_entry: context.client_entry,
  )
}
