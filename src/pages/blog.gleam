import components/dock
import components/icons
import components/side_nav.{Item}
import features/blog/feed
import features/blog/post.{type Post}
import features/blog/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/string
import hinoto/body.{type Body}
import layouts/base
import lib/cn.{cn}
import lib/terminal
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}
import server/middleware
import server/respond
import server/user_agent.{Browser, Terminal}

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use client <- user_agent.detect(req)
  use posts <- promise.map(store.list(context))

  case posts, client {
    Ok(posts), Terminal -> respond.text(200, text_view(posts))
    Ok(posts), Browser -> respond.html(200, view(context, posts))
    Error(Nil), _ -> respond.text(503, "Service Unavailable")
  }
}

fn text_view(posts: List(Post)) -> String {
  terminal.document([
    [terminal.dim("mst-mkt/") <> terminal.bold("blog")],
    case posts {
      [] -> [terminal.dim("No posts.")]
      _ ->
        terminal.table(
          list.map(posts, fn(entry) {
            let url = base.origin <> post.page_path(entry.slug)

            [terminal.dim(entry.published_at), terminal.link(entry.title, url)]
          }),
        )
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
    head: [base.canonical(post.list_path), feed.link()],
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
    html.ul([attribute.class("grid gap-y-3")], list.map(posts, view_post)),
  ])
}

fn view_post(entry: Post) -> Element(Nil) {
  html.li([], [
    html.a(
      [
        attribute.href(post.page_path(entry.slug)),
        attribute.class(
          cn([
            "group flex items-center gap-x-4 rounded-sm",
            "outline-offset-4 focus-visible:outline-2 focus-visible:outline-fg",
          ]),
        ),
      ],
      [
        view_date(entry.published_at),
        html.span([attribute.class("flex min-w-0 grow items-center gap-x-2")], [
          html.img([
            attribute.src(post.emoji_url(entry.emoji)),
            attribute.alt(""),
            attribute.class(
              "size-4 shrink-0 opacity-60 transition-opacity group-hover:opacity-100",
            ),
          ]),
          html.span(
            [
              attribute.class(
                "truncate text-sm text-muted transition-colors group-hover:text-fg group-focus-visible:text-fg",
              ),
            ],
            [html.text(entry.title)],
          ),
        ]),
      ],
    ),
  ])
}

fn view_date(date: String) -> Element(Nil) {
  let attributes = [
    attribute.attribute("datetime", date),
    attribute.class("shrink-0 font-mono text-xs text-muted tabular-nums"),
  ]

  case string.split(date, "-") {
    [year, month, day] ->
      html.time(attributes, [
        html.span([attribute.class("text-fg/40")], [html.text(year <> ".")]),
        html.text(month <> "." <> day),
      ])
    _ -> html.time(attributes, [html.text(date)])
  }
}
