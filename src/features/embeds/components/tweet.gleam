import components/icons
import components/text_link
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/string
import lib/cn.{cn}
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Tweet {
  Tweet(
    url: String,
    name: String,
    handle: String,
    avatar: String,
    text: List(Segment),
    media: List(Media),
    date: String,
  )
}

pub type Segment {
  Text(String)
  Link(text: String, href: String)
}

pub type Media {
  Photo(url: String, width: Int, height: Int, alt: Option(String))
  Video(poster: String, src: String, width: Int, height: Int, gif: Bool)
}

pub fn view(tweet: Tweet) -> Element(msg) {
  html.article(
    [attribute.class("grid gap-y-3 rounded-lg border border-border p-4")],
    [
      html.header([attribute.class("flex items-center gap-x-3")], [
        html.img([
          attribute.src(tweet.avatar),
          attribute.alt(""),
          attribute.loading("lazy"),
          attribute.class("size-10 rounded-full"),
        ]),
        html.p([attribute.class("grid min-w-0 flex-1")], [
          html.span([attribute.class("flex items-baseline gap-x-2")], [
            html.span([attribute.class("truncate text-sm/tight font-bold")], [
              html.text(tweet.name),
            ]),
            html.a(
              [
                attribute.href(tweet.url),
                attribute.aria_hidden(True),
                attribute.tabindex(-1),
                attribute.class(
                  "ml-auto shrink-0 text-subtle transition-colors hover:text-fg",
                ),
              ],
              [icons.twitter([attribute.class("size-4 cap-center")])],
            ),
          ]),
          html.span([attribute.class("truncate text-xs/tight text-subtle")], [
            html.text("@" <> tweet.handle),
          ]),
        ]),
      ]),
      html.p(
        [attribute.class("text-sm/relaxed whitespace-pre-line")],
        list.map(tweet.text, fn(segment) {
          case segment {
            Text(text) -> html.text(text)
            Link(text:, href:) -> text_link.view(text, href)
          }
        }),
      ),
      view_media(tweet.media),
      html.a(
        [
          attribute.href(tweet.url),
          attribute.class(
            "flex w-fit items-baseline gap-x-1 rounded-xs text-xs text-subtle outline-offset-2 transition-colors hover:text-fg focus-visible:outline-2 focus-visible:outline-fg",
          ),
        ],
        [
          html.time([attribute.datetime(tweet.date)], [
            html.text(tweet.date),
          ]),
          html.span([attribute.aria_hidden(True)], [html.text("·")]),
          html.text("View on Twitter"),
          icons.arrow_up_right([
            attribute.aria_hidden(True),
            attribute.class("size-3 cap-center"),
          ]),
        ],
      ),
    ],
  )
}

fn view_media(media: List(Media)) -> Element(msg) {
  let cell = "size-full object-cover"
  let grid = html.div(
    [
      attribute.class(
        "grid aspect-video grid-cols-2 gap-0.5 overflow-clip rounded-md border border-border",
      ),
    ],
    _,
  )

  case media {
    [] -> element.none()
    [single] ->
      view_medium(
        single,
        "max-h-128 w-full rounded-md border border-border bg-control object-contain",
      )
    [first, second, third] ->
      grid([
        view_medium(first, cn(["row-span-2", cell])),
        view_medium(second, cell),
        view_medium(third, cell),
      ])
    _ -> grid(list.map(media, view_medium(_, cell)))
  }
}

fn view_medium(medium: Media, class: String) -> Element(msg) {
  case medium {
    Photo(url:, width:, height:, alt:) ->
      html.img([
        attribute.src(url),
        attribute.alt(option.unwrap(alt, "")),
        attribute.loading("lazy"),
        attribute.width(width),
        attribute.height(height),
        attribute.class(class),
      ])
    Video(poster:, src:, width:, height:, gif:) ->
      html.video(
        [
          attribute.src(src),
          attribute.poster(poster),
          attribute.width(width),
          attribute.height(height),
          attribute.style(
            "aspect-ratio",
            int.to_string(width) <> " / " <> int.to_string(height),
          ),
          attribute.class(cn(["bg-control", class])),
          ..case gif {
            True -> [
              attribute.autoplay(True),
              attribute.loop(True),
              attribute.muted(True),
              attribute.playsinline(True),
            ]
            False -> [attribute.controls(True), attribute.preload("none")]
          }
        ],
        [],
      )
  }
}

@internal
pub fn stories() -> List(Story) {
  let og_image = "https://nuten.keito.dev/og-image.png"
  let photo = Photo(url: og_image, width: 1280, height: 640, alt: None)
  let video =
    Video(poster: og_image, src: "", width: 1280, height: 640, gif: False)
  let tweet =
    Tweet(
      url: "https://x.com/mst_mkt_/status/1",
      name: "mst-mkt",
      handle: "mst_mkt_",
      avatar: "/avatar.png",
      text: [
        Text("Sample text with a link and a hashtag.\n\n"),
        Link("example.com", "https://example.com/"),
        Text(" "),
        Link("#example", "https://x.com/hashtag/example"),
      ],
      media: [],
      date: "2026-11-04",
    )
  let new = fn(variant, tweet: Tweet) {
    let plain =
      list.map(tweet.text, fn(segment) {
        case segment {
          Text(text) -> text
          Link(text:, ..) -> text
        }
      })
      |> string.concat

    story.new(variant, {
      use name <- story.text("name", tweet.name)
      use handle <- story.text("handle", tweet.handle)
      use text <- story.text("text", plain)
      let text = case text == plain {
        True -> tweet.text
        False -> [Text(text)]
      }
      use date <- story.text("date", tweet.date)

      story.render(view(Tweet(..tweet, name:, handle:, text:, date:)))
    })
  }
  let with_media = fn(variant, media) { new(variant, Tweet(..tweet, media:)) }

  [
    new("default", tweet),
    with_media("photo", [photo]),
    with_media("two-photos", [photo, photo]),
    with_media("three-photos", [photo, photo, photo]),
    with_media("four-photos", [photo, photo, photo, photo]),
    with_media("video", [video]),
    new(
      "long-text",
      Tweet(
        ..tweet,
        name: string.repeat("Long name ", 5),
        handle: string.repeat("long_", 3),
        text: [
          Text(string.repeat("Long text ", 25) <> "\n\n"),
          Link(
            "example.com/" <> string.repeat("long-path/", 6),
            "https://example.com/" <> string.repeat("long-path/", 6),
          ),
          Text(" "),
          Link("#long", "https://x.com/hashtag/long"),
        ],
      ),
    ),
  ]
}
