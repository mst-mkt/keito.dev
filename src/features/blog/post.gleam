import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/uri

pub type Post {
  Post(
    slug: String,
    title: String,
    emoji: String,
    description: Option(String),
    published_at: String,
    updated_at: Option(String),
    event: Option(Event),
  )
}

pub type Event {
  Event(name: String, url: String)
}

pub const list_path = "/blog"

pub const feed_path = "/blog/atom.xml"

pub fn page_path(slug: String) -> String {
  list_path <> "/" <> slug
}

pub fn decoder() -> Decoder(Post) {
  use slug <- decode.field("slug", decode.string)
  use title <- decode.field("title", decode.string)
  use emoji <- decode.optional_field("emoji", "🧶", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.map(decode.string, Some),
  )
  use published_at <- decode.field("publishedAt", decode.string)
  use updated_at <- decode.optional_field(
    "updatedAt",
    None,
    decode.map(decode.string, Some),
  )
  use event <- decode.optional_field(
    "event",
    None,
    decode.map(event_decoder(), Some),
  )

  decode.success(Post(
    slug:,
    title:,
    emoji:,
    description:,
    published_at:,
    updated_at:,
    event:,
  ))
}

fn event_decoder() -> Decoder(Event) {
  use name <- decode.field("name", decode.string)
  use url <- decode.field("url", decode.string)

  decode.success(Event(name:, url:))
}

pub fn display_date(date: String) -> String {
  case string.split(date, "-") |> list.try_map(int.parse) {
    Ok([year, month, day]) ->
      int.to_string(year)
      <> "年"
      <> int.to_string(month)
      <> "月"
      <> int.to_string(day)
      <> "日"
    _ -> date
  }
}

pub fn emoji_url(emoji: String) -> String {
  "https://serenity.keito.dev/" <> uri.percent_encode(emoji) <> "/svg"
}

pub fn group_by_year(posts: List(Post)) -> List(#(String, List(Post))) {
  list.chunk(posts, year)
  |> list.filter_map(fn(posts) {
    case posts {
      [first, ..] -> Ok(#(year(first), posts))
      [] -> Error(Nil)
    }
  })
}

fn year(post: Post) -> String {
  string.slice(post.published_at, 0, 4)
}
