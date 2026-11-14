import components/icons
import gleam/option.{type Option, None, Some}
import gleam/string
import lib/number_format
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Repository {
  Repository(
    url: String,
    owner: String,
    name: String,
    description: Option(String),
    stars: Int,
    language: Option(Language),
  )
}

pub type Language {
  Language(name: String, color: String)
}

pub fn view(repository: Repository) -> Element(msg) {
  html.a(
    [
      attribute.href(repository.url),
      attribute.class(
        "flex flex-col gap-y-2 rounded-lg border border-border px-4 py-3 outline-offset-2 transition-colors hover:bg-control focus-visible:outline-2 focus-visible:outline-fg",
      ),
    ],
    [
      html.p([attribute.class("flex items-baseline gap-x-2 text-sm")], [
        icons.github([
          attribute.aria_hidden(True),
          attribute.class("size-4 shrink-0 cap-center"),
        ]),
        html.span([attribute.class("truncate")], [
          html.text(repository.owner <> "/"),
          html.span([attribute.class("font-bold")], [html.text(repository.name)]),
        ]),
      ]),
      case repository.description {
        Some(description) ->
          html.p([attribute.class("line-clamp-2 text-xs/normal text-subtle")], [
            html.text(description),
          ])
        None -> element.none()
      },
      html.p(
        [
          attribute.class("flex items-baseline gap-x-4 text-xs text-subtle"),
        ],
        [
          html.span([attribute.class("flex items-baseline gap-x-1")], [
            icons.star([
              attribute.role("img"),
              attribute.aria_label("Stars"),
              attribute.class("size-3.5 cap-center"),
            ]),
            html.text(number_format.compact(repository.stars)),
          ]),
          case repository.language {
            Some(language) ->
              html.span([attribute.class("flex items-baseline gap-x-1.5")], [
                html.span(
                  [
                    attribute.style("background-color", language.color),
                    attribute.class("size-2.5 cap-center rounded-full"),
                  ],
                  [],
                ),
                html.text(language.name),
              ])
            None -> element.none()
          },
        ],
      ),
    ],
  )
}

@internal
pub fn stories() -> List(Story) {
  let repository =
    Repository(
      url: "https://github.com/mst-mkt/nuten",
      owner: "mst-mkt",
      name: "nuten",
      description: Some(
        "A formatter for Nushell. Robust, fast, and lightweight.",
      ),
      stars: 1,
      language: Some(Language(name: "Rust", color: "#dea584")),
    )
  let new = fn(variant, repository: Repository) {
    story.new(variant, {
      use owner <- story.text("owner", repository.owner)
      use name <- story.text("name", repository.name)
      use description <- story.optional(
        "description",
        repository.description,
        otherwise: "",
        control: story.text,
      )
      use stars <- story.number("stars", repository.stars)
      use language <- story.optional(
        "language",
        option.map(repository.language, fn(language) { language.name }),
        otherwise: "",
        control: story.text,
      )
      use color <- story.text("color", case repository.language {
        Some(language) -> language.color
        None -> "#dea584"
      })
      let language = option.map(language, fn(name) { Language(name:, color:) })

      story.render(view(
        Repository(..repository, owner:, name:, description:, stars:, language:),
      ))
    })
  }

  [
    new("default", repository),
    new("many-stars", Repository(..repository, stars: 52_300)),
    new("without-language", Repository(..repository, language: None)),
    new("without-description", Repository(..repository, description: None)),
    new(
      "long-text",
      Repository(
        ..repository,
        owner: string.repeat("long-", 6) <> "owner",
        name: string.repeat("long-", 12) <> "name",
        description: Some(string.repeat("Long description ", 20)),
      ),
    ),
  ]
}
