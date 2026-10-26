import components/avatar
import components/icons
import components/text_link
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import hinoto/body.{type Body}
import layouts/base
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}
import server/respond

const links = [
  #("GitHub", "mst-mkt", "https://github.com/mst-mkt"),
  #("Twitter", "mst_mkt_", "https://twitter.com/mst_mkt_"),
  #("Discord", "mst_mkt", "https://discord.com/users/1089919802702823614"),
  #("mixi2", "mst_mkt", "https://mixi.social/@mst_mkt"),
]

pub fn handle(
  _req: Request(Body),
  _context: Context,
) -> Promise(Response(Body)) {
  promise.resolve(respond.html(200, view()))
}

fn view() -> Element(Nil) {
  base.document(
    "Home",
    left: [],
    content: [
      html.div([attribute.class("grid enter gap-y-12")], [
        html.header([attribute.class("grid gap-y-4")], [
          avatar.view(),
          html.hgroup([], [
            html.h1([attribute.class("text-2xl font-bold")], [
              html.text("mst-mkt"),
            ]),
            html.p([attribute.class("text-muted")], [html.text("keito /keːto/")]),
          ]),
        ]),
        html.div([], [
          html.p([], [
            html.text("Software engineer."),
            html.br([]),
            html.text(
              "Interested in web frontend, microblogging, JavaScript toolchains, Linux desktop, Nix, Nushell, and more.",
            ),
          ]),
          html.p([], [
            html.text("Computer science undergraduate at "),
            text_link.with_icon("INIAD", "https://www.iniad.org/", icons.iniad),
            html.text("."),
            html.br([]),
            html.text("Working part-time at "),
            text_link.with_icon("Hatena", "https://hatena.co.jp/", icons.hatena),
            html.text("."),
          ]),
          html.p([], [
            html.text("Building and maintaining "),
            text_link.with_icon(
              "Nuten",
              "https://nuten.keito.dev/",
              icons.nuten,
            ),
            html.text(", "),
            text_link.view(
              "mixi2-application-sdk-ts",
              "https://github.com/mst-mkt/mixi2-application-sdk-ts",
            ),
            html.text(", "),
            text_link.view(
              "autopair.nu",
              "https://github.com/mst-mkt/autopair.nu",
            ),
            html.text(", "),
            text_link.view(
              "omniwm.nix",
              "https://github.com/mst-mkt/omniwm.nix",
            ),
            html.text(", and more."),
          ]),
        ]),
        html.ul(
          [attribute.aria_label("Links"), attribute.class("grid gap-y-1")],
          list.map(links, fn(entry) {
            let #(service, id, href) = entry
            html.li([], [
              html.a(
                [
                  attribute.href(href),
                  attribute.class(
                    "group flex items-center gap-x-3 rounded-sm outline-offset-4 focus-visible:outline-2 focus-visible:outline-fg",
                  ),
                ],
                [
                  html.span([], [html.text(service)]),
                  html.span(
                    [
                      attribute.aria_hidden(True),
                      attribute.class(
                        "flex-1 border-t border-dashed border-border transition-colors group-hover:border-muted group-focus-visible:border-muted",
                      ),
                    ],
                    [],
                  ),
                  html.span(
                    [
                      attribute.class(
                        "text-subtle transition-colors group-hover:text-fg group-focus-visible:text-fg",
                      ),
                    ],
                    [html.text(id)],
                  ),
                ],
              ),
            ])
          }),
        ),
      ]),
    ],
    right: [],
    scripts: [],
  )
}
