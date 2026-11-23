import features/blog/post.{type Post, Event, Post}
import gleam/json
import gleam/option.{None, Some}

fn new_post(slug: String, published_at: String) -> Post {
  Post(
    slug:,
    title: slug,
    emoji: "🧶",
    description: None,
    published_at:,
    updated_at: None,
    event: None,
  )
}

pub fn decoder_test() {
  let body =
    json.object([
      #("slug", json.string("a")),
      #("title", json.string("A")),
      #("emoji", json.string("🛫")),
      #("description", json.string("B")),
      #("publishedAt", json.string("2025-11-15")),
      #("updatedAt", json.string("2025-12-07")),
      #(
        "event",
        json.object([
          #("name", json.string("C")),
          #("url", json.string("https://example.com")),
        ]),
      ),
    ])
    |> json.to_string

  let result = json.parse(body, post.decoder())

  assert result
    == Ok(Post(
      slug: "a",
      title: "A",
      emoji: "🛫",
      description: Some("B"),
      published_at: "2025-11-15",
      updated_at: Some("2025-12-07"),
      event: Some(Event(name: "C", url: "https://example.com")),
    ))
}

pub fn decoder_defaults_test() {
  let body =
    json.object([
      #("slug", json.string("a")),
      #("title", json.string("a")),
      #("publishedAt", json.string("2025-11-15")),
    ])
    |> json.to_string

  let result = json.parse(body, post.decoder())

  assert result == Ok(new_post("a", "2025-11-15"))
}

pub fn image_url_test() {
  assert post.image_url("a", "./b.webp") == "/blog/a/b.webp"
  assert post.image_url("a", "https://example.com/b.webp")
    == "https://example.com/b.webp"
}

pub fn display_date_test() {
  let date = "2025-12-07"

  let displayed = post.display_date(date)

  assert displayed == "2025年12月7日"
}

pub fn group_by_year_test() {
  let posts = [
    new_post("c", "2026-01-01"),
    new_post("b", "2025-12-31"),
    new_post("a", "2025-01-01"),
  ]

  let groups = post.group_by_year(posts)

  assert groups
    == [
      #("2026", [new_post("c", "2026-01-01")]),
      #("2025", [new_post("b", "2025-12-31"), new_post("a", "2025-01-01")]),
    ]
}

pub fn recent_test() {
  let posts = [
    new_post("c", "2026-11-03"),
    new_post("b", "2025-11-17"),
    new_post("a", "2025-11-16"),
  ]

  let recent = post.recent(posts, at: "2026-11-17")

  assert recent == [new_post("c", "2026-11-03"), new_post("b", "2025-11-17")]
}

pub fn recent_leap_day_test() {
  let posts = [new_post("b", "2027-03-01"), new_post("a", "2027-02-28")]

  let recent = post.recent(posts, at: "2028-02-29")

  assert recent == [new_post("b", "2027-03-01")]
}
