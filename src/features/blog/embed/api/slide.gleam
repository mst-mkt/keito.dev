import features/blog/embed/api/cache
import features/blog/embed/api/remote
import features/blog/embed/components/slide.{type Slide, Slide}
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/string
import gleam/uri
import server/context.{type Context}

pub fn speaker_deck(
  context: Context,
  url: String,
) -> Promise(Result(Slide, Nil)) {
  fetch(context, "https://speakerdeck.com/oembed.json", url)
}

pub fn docswell(context: Context, url: String) -> Promise(Result(Slide, Nil)) {
  fetch(context, "https://www.docswell.com/service/oembed", url)
}

fn fetch(
  context: Context,
  endpoint: String,
  url: String,
) -> Promise(Result(Slide, Nil)) {
  let oembed = endpoint <> "?format=json&url=" <> uri.percent_encode(url)
  use body <- promise.map(
    cache.get(context, "slide:" <> url, fn() {
      remote.get(oembed, remote.read_text)
    }),
  )

  cache.parse(body, decoder())
}

@internal
pub fn decoder() -> Decoder(Slide) {
  use title <- decode.field("title", decode.string)
  use player <- decode.field("html", {
    use html <- decode.then(decode.string)
    let src =
      string.split_once(html, "src=\"")
      |> result.try(fn(pair) { string.split_once(pair.1, "\"") })

    case src {
      Ok(#(src, _)) -> decode.success(src)
      Error(Nil) -> decode.failure("", "iframe src")
    }
  })
  use width <- decode.field("width", decode.int)
  use height <- decode.field("height", decode.int)

  decode.success(Slide(title:, player:, width:, height:))
}
