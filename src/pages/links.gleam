import components/button
import components/icons
import components/side_nav.{Item}
import features/links/brand
import features/links/link.{type Link}
import features/links/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import hinoto/body.{type Body}
import layouts/base
import lib/cn.{cn}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}
import server/middleware
import server/respond

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use links <- promise.map(store.list(context.env))

  respond.html(200, view(links))
}

fn view(links: List(Link)) -> Element(Nil) {
  base.document(
    "Links",
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
      ]),
    ],
    content: [
      html.div([attribute.class("grid enter gap-y-12")], [
        html.hgroup([attribute.class("grid")], [
          html.p([attribute.class("text-sm text-subtle")], [
            html.text("mst-mkt/"),
          ]),
          html.h1([attribute.class("text-2xl font-bold")], [
            html.text("links"),
          ]),
        ]),
        case links {
          [] ->
            html.p([attribute.class("text-muted")], [html.text("No links.")])
          _ ->
            html.ul(
              [
                attribute.aria_label("Links"),
                attribute.class("-mx-4 grid gap-y-1"),
              ],
              list.map(links, view_item),
            )
        },
      ]),
    ],
    right: [
      side_nav.view("Actions", [
        Item("Add link", link.new_path, icons.plus),
      ]),
    ],
    scripts: [],
  )
}

fn view_item(item: Link) -> Element(Nil) {
  let icon = brand.icon(item.url)
  let display_url = link.display_url(item.url)

  html.li([attribute.class("relative")], [
    html.a(
      [
        attribute.href(link.page_path(item.id)),
        attribute.class(
          cn([
            "peer grid grid-cols-[auto_1fr] items-center gap-x-3 gap-y-0.5",
            "rounded-lg py-3 pr-16 pl-4",
            "hover:bg-control",
            "outline-0 outline-fg/25 outline-solid focus-visible:outline-3",
            "transition-[color,background-color,outline-width] duration-100 ease-out",
          ]),
        ),
      ],
      [
        icon([attribute.aria_hidden(True), attribute.class("size-5")]),
        html.span([attribute.class("truncate")], [html.text(item.name)]),
        html.span([attribute.class("col-span-2 truncate text-sm text-subtle")], [
          html.text(display_url),
        ]),
      ],
    ),
    button.new()
      |> button.variant(button.Ghost)
      |> button.size(button.Icon)
      |> button.class(
        "absolute top-1/2 right-3 -translate-y-1/2 peer-hover:bg-bg",
      )
      |> button.link(
        item.url,
        [
          attribute.aria_label("Open " <> item.name),
          attribute.title(display_url),
        ],
        [icons.open_new_window([attribute.aria_hidden(True)])],
      ),
  ])
}
