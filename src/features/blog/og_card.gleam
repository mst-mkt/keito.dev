import budoux
import features/blog/post.{type Post}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/uri
import lib/og_image
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type OgCard {
  OgCard(title: String, emoji: String, description: Option(String))
}

const color_bg = "oklch(0.98 0 0)"

const color_fg = "oklch(0.2 0 0)"

const color_muted =
  "color-mix(in oklch, " <> color_fg <> " 70%, " <> color_bg <> ")"

const color_subtle =
  "color-mix(in oklch, " <> color_fg <> " 60%, " <> color_bg <> ")"

const color_border =
  "color-mix(in oklch, " <> color_fg <> " 10%, " <> color_bg <> ")"

const zero_width_space = "\u{200B}"

pub fn from_post(entry: Post) -> OgCard {
  OgCard(title: entry.title, emoji: entry.emoji, description: entry.description)
}

pub fn to_query(card: OgCard) -> String {
  let description = case card.description {
    Some(description) -> [#("description", description)]
    None -> []
  }

  uri.query_to_string([
    #("title", card.title),
    #("emoji", card.emoji),
    ..description
  ])
}

pub fn view(card: OgCard) -> Element(Nil) {
  let description = case card.description {
    Some("") -> None
    description -> description
  }
  let title_lines = case description {
    Some(_) -> 2
    None -> 3
  }
  let parser = budoux.ja()

  html.div(
    [
      attribute.lang("ja"),
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("width", "100%"),
        #("height", "100%"),
        #("padding", "72px 96px 64px"),
        #("background-color", color_bg),
        #("color", color_fg),
        #("font-family", og_image.font),
      ]),
    ],
    [
      html.div(
        [
          attribute.styles([
            #("display", "flex"),
            #("flex-direction", "column"),
            #("justify-content", "center"),
            #("flex-grow", "1"),
          ]),
        ],
        [
          html.img([
            attribute.src(post.emoji_url(card.emoji, post.Png(size: 160))),
            attribute.styles([
              #("height", "80px"),
              #("align-self", "flex-start"),
              #("margin-bottom", "40px"),
            ]),
          ]),
          html.div(
            [
              attribute.styles([
                #("font-size", "56px"),
                #("font-weight", "700"),
                #("line-height", "1.4"),
                #("line-clamp", int.to_string(title_lines)),
                #("word-break", "keep-all"),
                #("overflow-wrap", "anywhere"),
              ]),
            ],
            [html.text(insert_phrase_breaks(parser, card.title))],
          ),
          case description {
            Some(description) ->
              html.div(
                [
                  attribute.styles([
                    #("margin-top", "20px"),
                    #("font-size", "24px"),
                    #("line-height", "1.75"),
                    #("color", color_muted),
                    #("line-clamp", "2"),
                    #("word-break", "keep-all"),
                    #("overflow-wrap", "anywhere"),
                  ]),
                ],
                [html.text(insert_phrase_breaks(parser, description))],
              )
            None -> element.none()
          },
        ],
      ),
      view_footer(),
    ],
  )
}

fn insert_phrase_breaks(parser: budoux.Parser, text: String) -> String {
  budoux.parse(parser, text)
  |> string.join(zero_width_space)
}

fn view_footer() -> Element(Nil) {
  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("align-items", "baseline"),
        #("gap", "16px"),
        #("padding-top", "40px"),
        #("font-size", "32px"),
        #("font-weight", "500"),
      ]),
    ],
    [
      html.span([], [html.text("mst-mkt")]),
      html.div(
        [
          attribute.styles([
            #("flex-grow", "1"),
            #("height", "2px"),
            #("translate", "0 -0.27em"),
            #(
              "background-image",
              "repeating-linear-gradient(to right, "
                <> color_border
                <> " 0 4px, transparent 4px 9px)",
            ),
          ]),
        ],
        [],
      ),
      html.span([attribute.styles([#("color", color_subtle)])], [
        html.text("keito.dev"),
      ]),
    ],
  )
}

@internal
pub fn stories() -> List(Story) {
  let card =
    OgCard(title: "記事タイトルのサンプル", emoji: "🧶", description: Some("記事の説明のサンプル"))
  let long =
    OgCard(
      ..card,
      title: string.repeat("長い記事タイトルのサンプル ", 8),
      description: Some(string.repeat("長い説明文のサンプル ", 20)),
    )
  let new = fn(variant, card: OgCard) {
    story.new(variant, {
      use title <- story.text("title", card.title)
      use emoji <- story.text("emoji", card.emoji)
      use description <- story.optional(
        "description",
        card.description,
        otherwise: "",
        control: story.text,
      )
      let card = OgCard(title:, emoji:, description:)

      story.render(
        html.img([
          attribute.src("/story/og.png?" <> to_query(card)),
          attribute.alt(""),
          attribute.class("aspect-ogp w-full max-w-3xl border border-border"),
        ]),
      )
    })
  }

  [
    new("default", card),
    new("without-description", OgCard(..card, description: None)),
    new("long-text", long),
    new("long-text-without-description", OgCard(..long, description: None)),
    new(
      "long-word",
      OgCard(..card, title: string.repeat("SampleTitleWithoutSpaces", 6)),
    ),
  ]
}
