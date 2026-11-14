import features/embeds/api/tweet as api
import features/embeds/components/tweet.{
  type Tweet, Link, Photo, Text, Tweet, Video,
}
import gleam/dict
import gleam/json.{type Json}
import gleam/option.{Some}

fn decode(fields: List(#(String, Json))) -> Result(Tweet, json.DecodeError) {
  let user =
    json.object([
      #("name", json.string("mst-mkt")),
      #("screen_name", json.string("mst_mkt_")),
      #(
        "profile_image_url_https",
        json.string("https://pbs.twimg.com/profile_images/1/avatar_normal.png"),
      ),
    ])
  let body =
    [
      #("user", user),
      #("text", json.string("")),
      #("display_text_range", json.array([0, 0], json.int)),
      #("created_at", json.string("2026-11-04T12:34:56.000Z")),
      ..fields
    ]
    |> dict.from_list
    |> dict.to_list
    |> json.object

  json.parse(
    json.to_string(body),
    api.decoder("https://x.com/mst_mkt_/status/1"),
  )
}

fn text(text: String, end: Int) -> List(#(String, Json)) {
  [
    #("text", json.string(text)),
    #("display_text_range", json.array([0, end], json.int)),
  ]
}

fn entity(start: Int, end: Int, fields: List(#(String, Json))) -> Json {
  json.object([#("indices", json.array([start, end], json.int)), ..fields])
}

fn medium(kind: String, fields: List(#(String, Json))) -> Json {
  json.object([
    #("type", json.string(kind)),
    #("media_url_https", json.string("https://pbs.twimg.com/media/1.jpg")),
    #(
      "original_info",
      json.object([#("width", json.int(1280)), #("height", json.int(640))]),
    ),
    ..fields
  ])
}

fn variant(content_type: String, bitrate: Int, url: String) -> Json {
  json.object([
    #("content_type", json.string(content_type)),
    #("bitrate", json.int(bitrate)),
    #("url", json.string(url)),
  ])
}

pub fn decoder_avatar_test() {
  let assert Ok(Tweet(avatar:, ..)) = decode([])

  assert avatar == "https://pbs.twimg.com/profile_images/1/avatar_bigger.png"
}

pub fn decoder_date_test() {
  let assert Ok(Tweet(date:, ..)) = decode([])

  assert date == "2026-11-04"
}

pub fn decoder_html_entity_test() {
  let fields = text("a &lt;b&gt;", 11)

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Text("a <b>")]
}

pub fn decoder_text_range_end_test() {
  let fields = text("text https://t.co/media", 4)

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Text("text")]
}

pub fn decoder_text_range_start_test() {
  let fields = [
    #(
      "entities",
      json.object([
        #(
          "user_mentions",
          json.preprocessed_array([
            entity(0, 9, [#("screen_name", json.string("mst_mkt_"))]),
          ]),
        ),
      ]),
    ),
    #("text", json.string("@mst_mkt_ text")),
    #("display_text_range", json.array([10, 14], json.int)),
  ]

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Text("text")]
}

pub fn decoder_url_entity_test() {
  let fields = [
    #(
      "entities",
      json.object([
        #(
          "urls",
          json.preprocessed_array([
            entity(5, 19, [
              #("display_url", json.string("example.com")),
              #("expanded_url", json.string("https://example.com")),
            ]),
          ]),
        ),
      ]),
    ),
    ..text("text https://t.co/x", 19)
  ]

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Text("text "), Link("example.com", "https://example.com")]
}

pub fn decoder_mention_test() {
  let fields = [
    #(
      "entities",
      json.object([
        #(
          "user_mentions",
          json.preprocessed_array([
            entity(0, 9, [#("screen_name", json.string("mst_mkt_"))]),
          ]),
        ),
      ]),
    ),
    ..text("@mst_mkt_", 9)
  ]

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Link("@mst_mkt_", "https://x.com/mst_mkt_")]
}

pub fn decoder_hashtag_test() {
  let fields = [
    #(
      "entities",
      json.object([
        #(
          "hashtags",
          json.preprocessed_array([
            entity(0, 8, [#("text", json.string("nushell"))]),
          ]),
        ),
      ]),
    ),
    ..text("#nushell", 8)
  ]

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Link("#nushell", "https://x.com/hashtag/nushell")]
}

pub fn decoder_codepoint_indices_test() {
  let fields = [
    #(
      "entities",
      json.object([
        #(
          "hashtags",
          json.preprocessed_array([
            entity(2, 10, [#("text", json.string("nushell"))]),
          ]),
        ),
      ]),
    ),
    ..text("🍣 #nushell", 10)
  ]

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Text("🍣 "), Link("#nushell", "https://x.com/hashtag/nushell")]
}

pub fn decoder_entity_order_test() {
  let fields = [
    #(
      "entities",
      json.object([
        #(
          "urls",
          json.preprocessed_array([
            entity(9, 23, [
              #("display_url", json.string("example.com")),
              #("expanded_url", json.string("https://example.com")),
            ]),
          ]),
        ),
        #(
          "hashtags",
          json.preprocessed_array([
            entity(0, 8, [#("text", json.string("nushell"))]),
          ]),
        ),
      ]),
    ),
    ..text("#nushell https://t.co/x", 23)
  ]

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text
    == [
      Link("#nushell", "https://x.com/hashtag/nushell"),
      Text(" "),
      Link("example.com", "https://example.com"),
    ]
}

pub fn decoder_entity_outside_range_test() {
  let fields = [
    #(
      "entities",
      json.object([
        #(
          "urls",
          json.preprocessed_array([
            entity(5, 19, [
              #("display_url", json.string("pic.x.com/1")),
              #("expanded_url", json.string("https://x.com/mst_mkt_/status/1")),
            ]),
          ]),
        ),
      ]),
    ),
    ..text("text https://t.co/x", 4)
  ]

  let assert Ok(Tweet(text:, ..)) = decode(fields)

  assert text == [Text("text")]
}

pub fn decoder_photo_test() {
  let fields = [
    #(
      "mediaDetails",
      json.preprocessed_array([
        medium("photo", [#("ext_alt_text", json.string("Alt"))]),
      ]),
    ),
  ]

  let assert Ok(Tweet(media:, ..)) = decode(fields)

  assert media
    == [
      Photo(
        url: "https://pbs.twimg.com/media/1.jpg",
        width: 1280,
        height: 640,
        alt: Some("Alt"),
      ),
    ]
}

pub fn decoder_video_test() {
  let variants =
    json.preprocessed_array([
      variant("application/x-mpegURL", 0, "https://video.twimg.com/1.m3u8"),
      variant("video/mp4", 432_000, "https://video.twimg.com/low.mp4"),
      variant("video/mp4", 1_280_000, "https://video.twimg.com/high.mp4"),
    ])
  let fields = [
    #(
      "mediaDetails",
      json.preprocessed_array([
        medium("video", [
          #("video_info", json.object([#("variants", variants)])),
        ]),
      ]),
    ),
  ]

  let assert Ok(Tweet(media:, ..)) = decode(fields)

  assert media
    == [
      Video(
        poster: "https://pbs.twimg.com/media/1.jpg",
        src: "https://video.twimg.com/high.mp4",
        width: 1280,
        height: 640,
        gif: False,
      ),
    ]
}

pub fn decoder_gif_test() {
  let variants =
    json.preprocessed_array([
      variant("video/mp4", 0, "https://video.twimg.com/1.mp4"),
    ])
  let fields = [
    #(
      "mediaDetails",
      json.preprocessed_array([
        medium("animated_gif", [
          #("video_info", json.object([#("variants", variants)])),
        ]),
      ]),
    ),
  ]

  let assert Ok(Tweet(media: [Video(gif:, ..)], ..)) = decode(fields)

  assert gif == True
}

pub fn decoder_unknown_media_test() {
  let fields = [
    #("mediaDetails", json.preprocessed_array([medium("unknown", [])])),
  ]

  let assert Ok(Tweet(media:, ..)) = decode(fields)

  assert media == []
}

pub fn decoder_without_media_test() {
  let assert Ok(Tweet(media:, ..)) = decode([])

  assert media == []
}
