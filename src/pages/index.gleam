import components/avatar
import components/icons
import components/text_link
import features/links/link.{type Link}
import features/links/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/string
import hinoto/body.{type Body}
import layouts/base
import lib/cn.{cn}
import lib/emoji
import lib/md
import lib/ogp
import lib/terminal
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import pages/sitemap
import server/context.{type Context}
import server/format.{Html, Markdown, Terminal}
import server/middleware
import server/respond

const links = [
  #("GitHub", "mst-mkt", "github"),
  #("Twitter", "mst_mkt_", "twitter"),
  #("Discord", "mst_mkt", "discord"),
  #("mixi2", "mst_mkt", "mixi2"),
]

const projects = [
  #("Nuten", "https://nuten.keito.dev/"),
  #(
    "mixi2-application-sdk-ts",
    "https://github.com/mst-mkt/mixi2-application-sdk-ts",
  ),
  #("autopair.nu", "https://github.com/mst-mkt/autopair.nu"),
  #("omniwm.nix", "https://github.com/mst-mkt/omniwm.nix"),
]

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use format <- format.negotiate(req)

  case format {
    Markdown -> promise.resolve(respond.markdown(200, markdown_view()))
    Terminal -> promise.resolve(respond.text(200, text_view()))
    Html -> {
      use profiles <- promise.map(store.list(context.env))

      respond.html(200, view(context, profiles))
      |> respond.link(sitemap.path, [
        #("rel", "sitemap"),
        #("type", "application/xml"),
      ])
    }
  }
}

fn markdown_view() -> String {
  let project_links =
    list.map(projects, fn(project) { md.link(project.0, project.1) })

  md.document([
    "# mst-mkt",
    "keito /keːto/",
    md.paragraph([
      "Software engineer.",
      "Interested in web frontend, microblogging, JavaScript toolchains, Linux desktop, Nix, Nushell, and more.",
    ]),
    md.paragraph([
      "Computer science undergraduate at "
        <> md.link("INIAD", "https://www.iniad.org/")
        <> ".",
      "Working part-time at "
        <> md.link("Hatena", "https://hatena.co.jp/")
        <> ".",
    ]),
    "Building and maintaining "
      <> string.join(project_links, ", ")
      <> ", and more.",
    md.list(
      list.map(links, fn(entry) {
        let #(service, account, id) = entry
        md.link(service, link.short_url(id)) <> ": " <> account
      }),
    ),
    md.link("More links", base.origin <> link.list_path),
  ])
}

fn text_view() -> String {
  let project_links =
    list.map(projects, fn(project) { inline_link(project.0, project.1) })

  terminal.document([
    terminal.beside(emoji.yarn, [
      "",
      terminal.bold("mst-mkt"),
      terminal.dim("keito /keːto/"),
    ]),
    terminal.paragraph([
      "Software engineer.",
      "Interested in web frontend, microblogging, JavaScript toolchains, Linux desktop, Nix, Nushell, and more.",
    ]),
    terminal.paragraph([
      "Computer science undergraduate at "
        <> inline_link("INIAD", "https://www.iniad.org/")
        <> ".",
      "Working part-time at "
        <> inline_link("Hatena", "https://hatena.co.jp/")
        <> ".",
    ]),
    terminal.paragraph([
      "Building and maintaining "
      <> string.join(project_links, ", ")
      <> ", and more.",
    ]),
    list.map(links, fn(entry) {
      let #(service, account, id) = entry
      let url = link.short_url(id)
      terminal.leader(
        terminal.link(service, url),
        terminal.link(terminal.dim(account), url),
      )
    }),
  ])
}

fn inline_link(text: String, url: String) -> String {
  terminal.link(terminal.underline(text), url)
}

fn view(context: Context, profiles: List(Link)) -> Element(Nil) {
  base.document(
    "",
    left: [],
    content: [
      html.div([attribute.class("h-card grid enter gap-y-12")], [
        html.header([attribute.class("grid gap-y-4")], [
          avatar.view(),
          html.hgroup([], [
            html.h1([attribute.class("p-name text-2xl font-bold")], [
              html.text("mst-mkt"),
            ]),
            html.p([attribute.class("text-muted")], [html.text("keito /keːto/")]),
          ]),
        ]),
        html.div([attribute.class("p-note")], [
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
            text_link.with_icon(
              "mixi2-application-sdk-ts",
              "https://github.com/mst-mkt/mixi2-application-sdk-ts",
              icons.mixi2_application_sdk_ts,
            ),
            html.text(", "),
            text_link.with_icon(
              "autopair.nu",
              "https://github.com/mst-mkt/autopair.nu",
              icons.autopair_nu,
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
                  "flex w-fit items-baseline gap-x-1 justify-self-end rounded-sm text-sm",
                  "text-subtle transition-colors hover:text-fg focus-visible:text-fg",
                  "outline-offset-4 focus-visible:outline-2 focus-visible:outline-fg",
                ]),
              ),
            ],
            [
              html.text("more"),
              icons.arrow_up_right([
                attribute.aria_hidden(True),
                attribute.class("size-3.5 cap-center"),
              ]),
            ],
          ),
        ]),
        html.data(
          [
            attribute.class("u-url u-uid"),
            attribute.value(base.origin <> "/"),
            attribute.hidden(True),
          ],
          [],
        ),
        html.data(
          [
            attribute.class("u-photo"),
            attribute.value(base.origin <> "/avatar.png"),
            attribute.hidden(True),
          ],
          [],
        ),
      ]),
    ],
    right: [],
    dock: [],
    head: [
      base.canonical("/"),
      ogp.property("og:type", "website"),
      ..list.map(profiles, fn(profile) {
        html.link([attribute.rel("me"), attribute.href(profile.url)])
      })
    ],
    client_entry: context.client_entry,
  )
}
