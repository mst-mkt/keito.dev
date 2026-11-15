import components/dock
import components/icons
import components/side_nav.{Item}
import features/blog/embed.{LinkCard}
import features/blog/feed
import features/blog/markdown.{type Section}
import features/blog/post.{type Post}
import features/blog/store.{type Article}
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{None, Some}
import hinoto/body.{type Body}
import layouts/base
import lib/cn.{cn}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html
import pages/not_found
import server/context.{type Context}
import server/middleware
import server/respond
import server/user_agent.{Browser, Terminal}

pub fn handle(
  req: Request(Body),
  context: Context,
  slug: String,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use client <- user_agent.detect(req)
  use found <- promise.await(store.get(context, slug))

  case found, client {
    Ok(_), Terminal -> {
      use source <- promise.map(store.source(context, slug))

      case source {
        Ok(source) -> respond.text(200, source)
        Error(Nil) -> respond.text(503, "Service Unavailable")
      }
    }
    Ok(entry), Browser -> {
      let event_card = case entry.event {
        Some(event) -> embed.view(context, LinkCard(event.url))
        None -> promise.resolve(element.none())
      }
      use article <- promise.await(store.article(context, slug))
      use event_card <- promise.map(event_card)

      case article {
        Ok(article) ->
          respond.html(200, view(context, entry, article, event_card))
        Error(Nil) -> respond.text(503, "Service Unavailable")
      }
    }
    Error(Nil), _ -> not_found.handle(req, context)
  }
}

fn view(
  context: Context,
  entry: Post,
  article: Article,
  event_card: Element(Nil),
) -> Element(Nil) {
  let sections =
    list.filter(article.sections, fn(section) { section.level <= 3 })
  let description = case entry.description {
    Some(description) -> [
      html.meta([attribute.name("description"), attribute.content(description)]),
      html.meta([
        attribute.attribute("property", "og:description"),
        attribute.content(description),
      ]),
    ]
    None -> []
  }

  base.document(
    entry.title,
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
        Item("Post list", post.list_path, icons.nav_arrow_left),
      ]),
    ],
    content: [
      html.article(
        [
          attribute.lang("ja"),
          attribute.class("grid enter grid-cols-1 gap-y-12"),
        ],
        [
          view_header(entry, event_card),
          element.unsafe_raw_html(
            "",
            "div",
            [attribute.class("markdown")],
            article.content,
          ),
        ],
      ),
    ],
    right: view_contents(sections),
    dock: [
      dock.Link("Home", "/", icons.home_simple_door),
      dock.Link("Post list", post.list_path, icons.list),
      ..case sections {
        [] -> []
        _ -> [
          dock.Panel(
            "Table of contents",
            [view_sections(sections)],
            icons.align_left,
          ),
        ]
      }
    ],
    head: [
      base.canonical(post.page_path(entry.slug)),
      feed.link(),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/entry/markdown.css"),
      ]),
      ..description
    ],
    client_entry: context.client_entry,
  )
}

fn view_header(entry: Post, event_card: Element(Nil)) -> Element(Nil) {
  html.header([attribute.class("grid grid-cols-1 gap-y-4")], [
    html.img([
      attribute.src(post.emoji_url(entry.emoji)),
      attribute.alt(""),
      attribute.class("my-6 size-16"),
    ]),
    html.h1([attribute.class("text-3xl font-bold")], [html.text(entry.title)]),
    case entry.description {
      Some(description) ->
        html.p([attribute.class("text-muted")], [html.text(description)])
      None -> element.none()
    },
    case entry.event {
      Some(event) ->
        html.div([attribute.class("grid grid-cols-1 gap-y-3")], [
          html.p(
            [
              attribute.class("flex items-baseline gap-x-2 text-xs text-subtle"),
            ],
            [
              icons.map_pin([
                attribute.aria_hidden(True),
                attribute.class("size-4 shrink-0 cap-center"),
              ]),
              html.a(
                [
                  attribute.href(event.url),
                  attribute.class(
                    "rounded-xs outline-offset-2 transition-colors hover:text-fg focus-visible:text-fg focus-visible:outline-2 focus-visible:outline-fg",
                  ),
                ],
                [html.text(event.name)],
              ),
            ],
          ),
          event_card,
        ])
      None -> element.none()
    },
    html.p(
      [attribute.class("flex flex-wrap gap-x-4 gap-y-2 text-xs text-subtle")],
      [
        view_date(icons.edit_pencil, "作成日", entry.published_at),
        case entry.updated_at {
          Some(updated_at) -> view_date(icons.refresh, "最終更新日", updated_at)
          None -> element.none()
        },
      ],
    ),
  ])
}

fn view_date(
  icon: fn(List(Attribute(Nil))) -> Element(Nil),
  label: String,
  value: String,
) -> Element(Nil) {
  html.span([attribute.class("flex items-baseline gap-x-2")], [
    icon([attribute.aria_hidden(True), attribute.class("size-4 cap-center")]),
    html.span([attribute.class("sr-only")], [html.text(label)]),
    html.time([attribute.attribute("datetime", value)], [
      html.text(post.display_date(value)),
    ]),
  ])
}

fn view_contents(sections: List(Section)) -> List(Element(Nil)) {
  case sections {
    [] -> []
    _ -> [
      html.nav(
        [
          attribute.aria_label("Table of contents"),
          attribute.class(
            cn([
              "-mx-2 -my-6 max-h-[calc(100dvh-6rem)] px-2 py-6",
              "scrollbar-none overflow-y-auto overscroll-contain",
              "mask-y-from-[calc(100%-1.5rem)]",
            ]),
          ),
        ],
        [view_sections(sections)],
      ),
    ]
  }
}

fn view_sections(sections: List(Section)) -> Element(Nil) {
  html.ul(
    [attribute.lang("ja"), attribute.class("grid gap-y-2 text-sm")],
    list.map(sections, view_section),
  )
}

fn view_section(section: Section) -> Element(Nil) {
  html.li([attribute.classes([#("pl-3", section.level == 3)])], [
    html.a(
      [
        attribute.href("#" <> section.id),
        attribute.class(
          "rounded-sm text-subtle outline-offset-4 transition-colors hover:text-fg focus-visible:text-fg focus-visible:outline-2 focus-visible:outline-fg",
        ),
      ],
      [html.text(section.title)],
    ),
  ])
}
