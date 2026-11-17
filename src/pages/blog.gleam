import components/dock
import components/icons
import components/side_nav.{Item}
import features/blog/feed
import features/blog/post.{type Post}
import features/blog/post_row
import features/blog/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import hinoto/body.{type Body}
import layouts/base
import lib/md
import lib/ogp
import lib/terminal
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}
import server/format.{Html, Markdown, Terminal}
import server/middleware
import server/respond

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use format <- format.negotiate(req)
  use posts <- promise.map(store.list(context))

  case posts, format {
    Ok(posts), Markdown -> respond.markdown(200, markdown_view(posts))
    Ok(posts), Terminal -> respond.text(200, text_view(posts))
    Ok(posts), Html -> respond.html(200, view(context, posts))
    Error(Nil), _ -> respond.text(503, "Service Unavailable")
  }
}

@internal
pub fn markdown_view(posts: List(Post)) -> String {
  md.document([
    "# Blog",
    case posts {
      [] -> "No posts."
      _ -> md.list(list.map(posts, post_row.markdown))
    },
  ])
}

fn text_view(posts: List(Post)) -> String {
  terminal.document([
    [terminal.dim("mst-mkt/") <> terminal.bold("blog")],
    case posts {
      [] -> [terminal.dim("No posts.")]
      _ -> terminal.table(list.map(posts, post_row.text))
    },
  ])
}

fn view(context: Context, posts: List(Post)) -> Element(Nil) {
  base.document(
    "Blog",
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
      ]),
    ],
    content: [
      html.div([attribute.class("grid enter gap-y-10")], [
        html.h1([attribute.class("sr-only")], [html.text("Blog")]),
        ..case posts {
          [] -> [
            html.p([attribute.class("text-muted")], [html.text("No posts.")]),
          ]
          _ -> list.map(post.group_by_year(posts), view_year)
        }
      ]),
    ],
    right: [
      side_nav.view("Feed", [
        Item("Subscribe to feed", post.feed_path, icons.rss_feed),
      ]),
    ],
    dock: [
      dock.Link("Home", "/", icons.home_simple_door),
      dock.Link("Subscribe to feed", post.feed_path, icons.rss_feed),
    ],
    head: [
      base.canonical(post.list_path),
      ogp.property("og:type", "website"),
      feed.link(),
    ],
    client_entry: context.client_entry,
  )
}

fn view_year(group: #(String, List(Post))) -> Element(Nil) {
  let #(year, posts) = group

  html.section([attribute.class("grid gap-y-4")], [
    html.h2(
      [
        attribute.class(
          "flex items-center gap-x-4 text-sm text-subtle after:h-px after:flex-1 after:bg-border",
        ),
      ],
      [html.text(year)],
    ),
    html.ul([attribute.class("grid gap-y-3")], list.map(posts, post_row.view)),
  ])
}
