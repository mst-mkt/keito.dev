import features/blog/embed/api/youtube as api
import features/blog/embed/components/youtube.{YouTube}
import gleam/json
import gleam/result

fn body(html: String) -> String {
  json.object([
    #("title", json.string("Never Gonna Give You Up")),
    #("html", json.string(html)),
  ])
  |> json.to_string
}

pub fn decoder_test() {
  let body =
    body(
      "<iframe width=\"200\" height=\"113\" src=\"https://www.youtube.com/embed/dQw4w9WgXcQ?start=30&feature=oembed\" allowfullscreen></iframe>",
    )

  let result = json.parse(body, api.decoder())

  assert result
    == Ok(YouTube(
      title: "Never Gonna Give You Up",
      player: "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?start=30&feature=oembed",
    ))
}

pub fn decoder_without_iframe_test() {
  let body = body("<p>Never Gonna Give You Up</p>")

  let decoded = json.parse(body, api.decoder())

  assert result.is_error(decoded)
}
