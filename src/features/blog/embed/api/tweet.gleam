import features/blog/embed/api/cache
import features/blog/embed/api/remote
import features/blog/embed/components/tweet.{
  type Media, type Segment, type Tweet, Link, Photo, Text, Tweet, Video,
}
import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{None}
import gleam/string
import lib/html_entity
import server/context.{type Context}

type Entity {
  Entity(start: Int, end: Int, link: Segment)
}

pub fn fetch(
  context: Context,
  url: String,
  id: String,
) -> Promise(Result(Tweet, Nil)) {
  let api = "https://react-tweet.vercel.app/api/tweet/" <> id
  use body <- promise.map(
    cache.get(context, "tweet:" <> id, fn() {
      remote.get(api, remote.read_text)
    }),
  )

  cache.parse(body, decode.at(["data"], decoder(url)))
}

@internal
pub fn decoder(url: String) -> Decoder(Tweet) {
  use name <- decode.subfield(["user", "name"], decode.string)
  use handle <- decode.subfield(["user", "screen_name"], decode.string)
  use avatar <- decode.subfield(
    ["user", "profile_image_url_https"],
    decode.string,
  )
  use text <- decode.field("text", decode.string)
  use range <- decode.field("display_text_range", range_decoder())
  use entities <- decode.optional_field("entities", [], entities_decoder())
  use media <- decode.optional_field(
    "mediaDetails",
    [],
    decode.list(decode.dynamic),
  )
  use created_at <- decode.field("created_at", decode.string)

  decode.success(Tweet(
    url:,
    name:,
    handle:,
    avatar: string.replace(avatar, "_normal.", "_bigger."),
    text: segments(text, range, entities),
    media: list.filter_map(media, decode.run(_, medium_decoder())),
    date: string.slice(created_at, 0, 10),
  ))
}

fn range_decoder() -> Decoder(#(Int, Int)) {
  use range <- decode.then(decode.list(decode.int))

  case range {
    [start, end] -> decode.success(#(start, end))
    _ -> decode.failure(#(0, 0), "range")
  }
}

fn entities_decoder() -> Decoder(List(Entity)) {
  use urls <- entities_field("urls", {
    use text <- decode.field("display_url", decode.string)
    use href <- decode.field("expanded_url", decode.string)

    decode.success(Link(text:, href:))
  })
  use mentions <- entities_field("user_mentions", {
    use name <- decode.field("screen_name", decode.string)

    decode.success(Link(text: "@" <> name, href: "https://x.com/" <> name))
  })
  use hashtags <- entities_field("hashtags", {
    use tag <- decode.field("text", decode.string)

    decode.success(Link(text: "#" <> tag, href: "https://x.com/hashtag/" <> tag))
  })

  [urls, mentions, hashtags]
  |> list.flatten
  |> list.sort(fn(a, b) { int.compare(a.start, b.start) })
  |> decode.success
}

fn entities_field(
  name: String,
  link: Decoder(Segment),
  next: fn(List(Entity)) -> Decoder(a),
) -> Decoder(a) {
  let entity = {
    use #(start, end) <- decode.field("indices", range_decoder())
    use link <- decode.then(link)

    decode.success(Entity(start:, end:, link:))
  }

  decode.optional_field(name, [], decode.list(entity), next)
}

fn medium_decoder() -> Decoder(Media) {
  use kind <- decode.field("type", decode.string)
  use url <- decode.field("media_url_https", decode.string)
  use width <- decode.subfield(["original_info", "width"], decode.int)
  use height <- decode.subfield(["original_info", "height"], decode.int)

  case kind {
    "photo" -> {
      use alt <- decode.optional_field(
        "ext_alt_text",
        None,
        decode.optional(decode.string),
      )

      decode.success(Photo(url:, width:, height:, alt:))
    }
    "video" | "animated_gif" -> {
      use src <- decode.subfield(["video_info", "variants"], mp4_decoder())

      decode.success(Video(
        poster: url,
        src:,
        width:,
        height:,
        gif: kind == "animated_gif",
      ))
    }
    _ -> decode.failure(Photo(url:, width:, height:, alt: None), "media")
  }
}

fn mp4_decoder() -> Decoder(String) {
  use variants <- decode.then(
    decode.list({
      use content_type <- decode.field("content_type", decode.string)
      use bitrate <- decode.optional_field("bitrate", 0, decode.int)
      use url <- decode.field("url", decode.string)

      decode.success(#(content_type, bitrate, url))
    }),
  )
  let best =
    variants
    |> list.filter(fn(variant) { variant.0 == "video/mp4" })
    |> list.max(fn(a, b) { int.compare(a.1, b.1) })

  case best {
    Ok(#(_, _, url)) -> decode.success(url)
    Error(Nil) -> decode.failure("", "mp4")
  }
}

fn segments(
  text: String,
  range: #(Int, Int),
  entities: List(Entity),
) -> List(Segment) {
  let #(start, end) = range
  let codepoints = string.to_utf_codepoints(text)
  let plain = fn(from, to) {
    codepoints
    |> list.drop(from)
    |> list.take(to - from)
    |> string.from_utf_codepoints
    |> html_entity.decode
    |> Text
  }
  let #(cursor, segments) =
    list.fold(entities, #(start, []), fn(state, entity) {
      let #(cursor, segments) = state

      case entity.start >= cursor && entity.end <= end {
        True -> #(entity.end, [
          entity.link,
          plain(cursor, entity.start),
          ..segments
        ])
        False -> state
      }
    })

  [plain(cursor, end), ..segments]
  |> list.reverse
  |> list.filter(fn(segment) { segment != Text("") })
}
