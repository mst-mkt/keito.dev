import components/icons
import gleam/option.{type Option, None, Some}
import gleam/string
import lib/number_format
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Package {
  Package(
    url: String,
    name: String,
    version: String,
    description: Option(String),
    downloads: Int,
  )
}

pub fn view(package: Package) -> Element(msg) {
  html.a(
    [
      attribute.href(package.url),
      attribute.class(
        "flex flex-col gap-y-2 rounded-lg border border-border px-4 py-3 outline-offset-2 transition-colors hover:bg-control focus-visible:outline-2 focus-visible:outline-fg",
      ),
    ],
    [
      html.p([attribute.class("flex items-baseline gap-x-2 text-sm")], [
        html.span([attribute.class("truncate font-bold")], [
          html.text(package.name),
        ]),
        html.span(
          [
            attribute.class(
              "shrink-0 rounded-sm bg-control px-1.5 py-1 text-xs/none text-subtle tabular-nums",
            ),
          ],
          [html.text(package.version)],
        ),
      ]),
      case package.description {
        Some(description) ->
          html.p([attribute.class("line-clamp-2 text-xs/normal text-subtle")], [
            html.text(description),
          ])
        None -> element.none()
      },
      html.p(
        [
          attribute.class("flex items-baseline gap-x-1 text-xs text-subtle"),
        ],
        [
          icons.download([
            attribute.aria_hidden(True),
            attribute.class("size-3.5 cap-center"),
          ]),
          html.text(
            number_format.compact(package.downloads) <> " weekly downloads",
          ),
        ],
      ),
    ],
  )
}

@internal
pub fn stories() -> List(Story) {
  let package =
    Package(
      url: "https://www.npmjs.com/package/@mst-mkt/mixi2-application-sdk-ts",
      name: "@mst-mkt/mixi2-application-sdk-ts",
      version: "1.0.1",
      description: Some("mixi2 Application SDK for TypeScript (Unofficial)"),
      downloads: 40,
    )
  let new = fn(variant, package: Package) {
    story.new(variant, {
      use name <- story.text("name", package.name)
      use version <- story.text("version", package.version)
      use description <- story.optional(
        "description",
        package.description,
        otherwise: "",
        control: story.text,
      )
      use downloads <- story.number("downloads", package.downloads)

      story.render(view(
        Package(..package, name:, version:, description:, downloads:),
      ))
    })
  }

  [
    new("default", package),
    new("without-description", Package(..package, description: None)),
    new(
      "long-text",
      Package(
        ..package,
        name: "@"
          <> string.repeat("long-", 6)
          <> "scope/"
          <> string.repeat("long-", 12)
          <> "name",
        version: "1.0.0-beta.12",
        description: Some(string.repeat("Long description ", 20)),
        downloads: 1_234_567,
      ),
    ),
  ]
}
