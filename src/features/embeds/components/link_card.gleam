import features/links/brand
import gleam/option.{type Option, None, Some}
import gleam/string
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type LinkCard {
  LinkCard(
    url: String,
    title: String,
    description: Option(String),
    image: Option(String),
    site: String,
    icon: Option(String),
  )
}

pub fn view(link_card: LinkCard) -> Element(msg) {
  html.a(
    [
      attribute.href(link_card.url),
      attribute.class(
        "group flex h-30 overflow-clip rounded-lg border border-border outline-offset-2 transition-colors hover:bg-control focus-visible:outline-2 focus-visible:outline-fg",
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            "flex min-w-0 flex-1 flex-col justify-center gap-y-2 px-4 py-3",
          ),
        ],
        [
          html.p([attribute.class("line-clamp-2 text-sm/snug font-bold")], [
            html.text(link_card.title),
          ]),
          case link_card.description {
            Some(description) ->
              html.p([attribute.class("truncate text-xs/normal text-subtle")], [
                html.text(description),
              ])
            None -> element.none()
          },
          html.p(
            [
              attribute.class(
                "flex items-baseline gap-x-1.5 text-xs text-subtle",
              ),
            ],
            [
              case link_card.icon {
                Some(icon) ->
                  html.img([
                    attribute.src(icon),
                    attribute.alt(""),
                    attribute.loading("lazy"),
                    attribute.class("size-3.5 shrink-0 cap-center rounded-xs"),
                  ])
                None ->
                  brand.icon(link_card.url)([
                    attribute.aria_hidden(True),
                    attribute.class("size-3.5 shrink-0 cap-center"),
                  ])
              },
              html.span([attribute.class("truncate")], [
                html.text(link_card.site),
              ]),
            ],
          ),
        ],
      ),
      case link_card.image {
        Some(image) ->
          html.div(
            [
              attribute.class(
                "relative aspect-square h-full shrink-0 border-l border-border after:absolute after:inset-0 after:bg-control after:opacity-0 after:transition-opacity group-hover:after:opacity-100 sm:aspect-ogp",
              ),
            ],
            [
              html.img([
                attribute.src(image),
                attribute.alt(""),
                attribute.loading("lazy"),
                attribute.class("size-full object-cover"),
              ]),
            ],
          )
        None -> element.none()
      },
    ],
  )
}

@internal
pub fn stories() -> List(Story) {
  let link_card =
    LinkCard(
      url: "https://nuten.keito.dev/",
      title: "Nuten",
      description: Some(
        "A formatter for Nushell. Robust, fast, and lightweight.",
      ),
      image: Some("https://nuten.keito.dev/og-image.png"),
      site: "nuten.keito.dev",
      icon: Some("https://nuten.keito.dev/logo.svg"),
    )
  let new = fn(variant, link_card: LinkCard) {
    story.new(variant, {
      use title <- story.text("title", link_card.title)
      use description <- story.optional(
        "description",
        link_card.description,
        otherwise: "",
        control: story.text,
      )
      use site <- story.text("site", link_card.site)
      use image <- story.optional(
        "image",
        link_card.image,
        otherwise: "",
        control: story.text,
      )
      use icon <- story.optional(
        "icon",
        link_card.icon,
        otherwise: "",
        control: story.text,
      )

      story.render(view(
        LinkCard(..link_card, title:, description:, site:, image:, icon:),
      ))
    })
  }

  [
    new("default", link_card),
    new("without-image", LinkCard(..link_card, image: None)),
    new("without-description", LinkCard(..link_card, description: None)),
    new("without-icon", LinkCard(..link_card, icon: None)),
    new(
      "long-text",
      LinkCard(
        ..link_card,
        title: string.repeat("Long title ", 20),
        description: Some(string.repeat("Long description ", 20)),
        site: string.repeat("Long site name ", 10),
      ),
    ),
  ]
}
