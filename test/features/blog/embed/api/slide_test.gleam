import features/blog/embed/api/slide as api
import features/blog/embed/components/slide.{Slide}
import gleam/json
import gleam/result

fn body(html: String) -> String {
  json.object([
    #("title", json.string("Introduction to SpeakerDeck")),
    #("html", json.string(html)),
    #("width", json.int(710)),
    #("height", json.int(532)),
  ])
  |> json.to_string
}

pub fn decoder_test() {
  let body =
    body(
      "<iframe class=\"speakerdeck-iframe\" src=\"https://speakerdeck.com/player/50021f75cf1db900020005e7\" width=\"710\" height=\"532\"></iframe>",
    )

  let result = json.parse(body, api.decoder())

  assert result
    == Ok(Slide(
      title: "Introduction to SpeakerDeck",
      player: "https://speakerdeck.com/player/50021f75cf1db900020005e7",
      width: 710,
      height: 532,
    ))
}

pub fn decoder_without_iframe_test() {
  let body = body("<p>Introduction to SpeakerDeck</p>")

  let decoded = json.parse(body, api.decoder())

  assert result.is_error(decoded)
}
