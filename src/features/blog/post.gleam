import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
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

pub fn og_image_path(slug: String) -> String {
  page_path(slug) <> "/og.png"
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

pub fn last_updated(entry: Post) -> String {
  option.unwrap(entry.updated_at, entry.published_at)
}

pub fn recent(posts: List(Post), at today: String) -> List(Post) {
  list.filter(posts, is_recent(_, today))
}

fn is_recent(entry: Post, today: String) -> Bool {
  string.compare(entry.published_at, one_year_before(today)) != order.Lt
}

fn one_year_before(date: String) -> String {
  {
    use #(year, rest) <- result.try(string.split_once(date, "-"))
    use year <- result.map(int.parse(year))

    int.to_string(year - 1) <> "-" <> rest
  }
  |> result.unwrap(date)
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

pub type EmojiFormat {
  Svg
  Png(size: Int)
}

pub fn emoji_url(emoji: String, format: EmojiFormat) -> String {
  let path = case format {
    Svg -> "/svg"
    Png(size:) -> "/png?size=" <> int.to_string(size)
  }

  "https://serenity.keito.dev/" <> uri.percent_encode(emoji) <> path
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
