import components/avatar
import components/icons
import components/text_link
import features/links/link
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

const links = [
  #("GitHub", "mst-mkt", "github"),
  #("Twitter", "mst_mkt_", "twitter"),
  #("Discord", "mst_mkt", "discord"),
  #("mixi2", "mst_mkt", "mixi2"),
]

pub fn handle(
  req: Request(Body),
  _context: Context,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])

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
        html.div([attribute.class("grid gap-y-3")], [
          html.ul(
            [attribute.aria_label("Links"), attribute.class("grid gap-y-1")],
            list.map(links, fn(entry) {
              let #(service, account, id) = entry
              html.li([], [
                html.a(
                  [
                    attribute.href(link.redirect_path(id)),
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
                      [html.text(account)],
                    ),
                  ],
                ),
              ])
            }),
          ),
          html.a(
            [
              attribute.href(link.list_path),
              attribute.class(
                cn([
                  "flex w-fit items-center gap-x-1 justify-self-end rounded-sm text-sm",
                  "text-subtle transition-colors hover:text-fg focus-visible:text-fg",
                  "outline-offset-4 focus-visible:outline-2 focus-visible:outline-fg",
                ]),
              ),
            ],
            [
              html.text("more"),
              icons.arrow_up_right([
                attribute.aria_hidden(True),
                attribute.class("size-3.5"),
              ]),
            ],
          ),
        ]),
      ]),
    ],
    right: [],
    scripts: [],
  )
}
