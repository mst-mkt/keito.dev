import features/blog/embed/api/cache
import features/blog/embed/api/remote
import features/blog/embed/components/youtube.{type YouTube, YouTube}
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/string
import gleam/uri
import server/context.{type Context}

pub fn fetch(context: Context, url: String) -> Promise(Result(YouTube, Nil)) {
  let oembed =
    "https://www.youtube.com/oembed?format=json&url=" <> uri.percent_encode(url)
  use body <- promise.map(
    cache.get(context, "youtube:" <> url, fn() {
      remote.get(oembed, remote.read_text)
    }),
  )

  cache.parse(body, decoder())
}

@internal
pub fn decoder() -> Decoder(YouTube) {
  use title <- decode.field("title", decode.string)
  use player <- decode.field("html", {
    use html <- decode.then(decode.string)
    let src =
      string.split_once(html, "src=\"")
      |> result.try(fn(pair) { string.split_once(pair.1, "\"") })

    case src {
      Ok(#(src, _)) -> decode.success(no_cookie(src))
      Error(Nil) -> decode.failure("", "iframe src")
    }
  })

  decode.success(YouTube(title:, player:))
}

fn no_cookie(player: String) -> String {
  case player {
    "https://www.youtube.com/embed/" <> rest ->
      "https://www.youtube-nocookie.com/embed/" <> rest
    _ -> player
  }
}
