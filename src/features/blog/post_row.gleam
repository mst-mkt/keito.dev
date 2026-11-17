import features/blog/post.{type Post}
import gleam/string
import layouts/base
import lib/cn.{cn}
import lib/md
import lib/terminal
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn markdown(entry: Post) -> String {
  let url = base.origin <> post.page_path(entry.slug)

  entry.published_at <> " " <> md.link(entry.title, url)
}

pub fn text(entry: Post) -> List(String) {
  let url = base.origin <> post.page_path(entry.slug)

  [terminal.dim(entry.published_at), terminal.link(entry.title, url)]
}

pub fn view(entry: Post) -> Element(msg) {
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

fn view_date(date: String) -> Element(msg) {
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
