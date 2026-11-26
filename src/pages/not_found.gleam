import components/text_link
import features/blog/post
import features/links/link
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/uri
import hinoto/body.{type Body}
import layouts/base
import lib/md
import lustre/attribute
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
    Html ->
      respond.html(
        404,
        view(context, result.unwrap(uri.percent_decode(req.path), req.path)),
      )
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

fn view(context: Context, path: String) -> Element(Nil) {
  base.document(
    "Not Found",
    og_image: base.og_image,
    left: [],
    content: [
      html.div([attribute.class("grid enter gap-y-8")], [
        html.h1([attribute.class("sr-only")], [html.text("Not Found")]),
        html.p([], [
          html.text("There is no page at "),
          html.code([attribute.class("font-mono text-sm wrap-anywhere")], [
            html.text(path),
          ]),
          html.text("."),
        ]),
        html.ul([attribute.class("flex flex-wrap gap-x-4 text-sm")], [
          html.li([], [text_link.view("Home", "/")]),
          html.li([], [text_link.view("Links", link.list_path)]),
          html.li([], [text_link.view("Blog", post.list_path)]),
        ]),
      ]),
    ],
    right: [],
    dock: [],
    head: [],
    client_entry: context.client_entry,
  )
}
