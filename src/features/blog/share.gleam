import components/button
import components/icons
import features/blog/post.{type Post}
import gleam/uri
import layouts/base
import lib/cn.{cn}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub const copy_id = "share-copy"

pub const sheet_id = "share-sheet"

pub const status_id = "share-status"

pub fn view(entry: Post) -> Element(msg) {
  let url = page_url(entry)

  html.footer(
    [
      attribute.class(
        "grid gap-y-3 rounded-lg bg-control px-5 py-4 sm:flex sm:items-center sm:gap-x-4",
      ),
    ],
    [
      html.div([attribute.class("flex min-w-0 grow items-center gap-x-4")], [
        html.img([
          attribute.src(post.emoji_url(entry.emoji, post.Svg)),
          attribute.alt(""),
          attribute.class("size-8 shrink-0"),
        ]),
        html.div([attribute.class("grid min-w-0 gap-y-0.5")], [
          html.p([attribute.class("text-xs text-subtle")], [
            html.text("Share this post"),
          ]),
          html.p(
            [attribute.class("text-sm font-bold wrap-anywhere sm:truncate")],
            [html.text(entry.title)],
          ),
        ]),
      ]),
      html.div([attribute.class("-ml-2 flex gap-x-1 sm:ml-0 sm:shrink-0")], [
        view_link(
          "Share on Twitter",
          intent_url("https://x.com/intent/post", entry),
          icons.twitter,
        ),
        view_link(
          "Share on Misskey",
          intent_url("https://misskey-hub.net/share/", entry),
          icons.misskey,
        ),
        view_button(copy_id, "Copy link", [attribute.data("url", url)], [
          html.span(
            [
              attribute.class(
                cn([
                  "grid *:col-start-1 *:row-start-1",
                  "*:transition-[opacity,filter] *:duration-200 *:ease-out",
                ]),
              ),
            ],
            [
              icons.copy([
                attribute.aria_hidden(True),
                attribute.class(
                  "group-data-copied:opacity-0 group-data-copied:blur-xs",
                ),
              ]),
              icons.check([
                attribute.aria_hidden(True),
                attribute.class(
                  "opacity-0 blur-xs group-data-copied:opacity-100 group-data-copied:blur-none",
                ),
              ]),
            ],
          ),
        ]),
        view_button(
          sheet_id,
          "Share",
          [attribute.data("url", url), attribute.data("title", entry.title)],
          [icons.share_ios([attribute.aria_hidden(True)])],
        ),
      ]),
      html.span(
        [
          attribute.id(status_id),
          attribute.role("status"),
          attribute.class("sr-only"),
        ],
        [],
      ),
    ],
  )
}

pub fn intent_url(endpoint: String, entry: Post) -> String {
  endpoint
  <> "?"
  <> uri.query_to_string([#("text", entry.title), #("url", page_url(entry))])
}

fn page_url(entry: Post) -> String {
  base.origin <> post.page_path(entry.slug)
}

fn view_link(
  label: String,
  href: String,
  icon: fn(List(Attribute(msg))) -> Element(msg),
) -> Element(msg) {
  icon_button()
  |> button.link(
    href,
    [
      attribute.target("_blank"),
      attribute.rel("noopener"),
      attribute.aria_label(label <> " (opens in a new tab)"),
    ],
    [icon([attribute.aria_hidden(True)])],
  )
}

fn view_button(
  id: String,
  label: String,
  attributes: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  icon_button()
  |> button.class("group")
  |> button.view(
    [
      attribute.type_("button"),
      attribute.id(id),
      attribute.aria_label(label),
      attribute.hidden(True),
      ..attributes
    ],
    children,
  )
}

fn icon_button() -> button.Button {
  button.new()
  |> button.variant(button.Ghost)
  |> button.size(button.Icon)
}
