import features/blog/post.{Post}
import features/blog/share
import gleam/option.{None}

pub fn intent_url_encodes_query_test() {
  let entry =
    Post(
      slug: "a",
      title: "a+b&c",
      emoji: "🧶",
      description: None,
      published_at: "2025-11-15",
      updated_at: None,
      event: None,
    )

  let url = share.intent_url("https://example.com/share", entry)

  assert url
    == "https://example.com/share?text=a%2Bb%26c&url=https%3A%2F%2Fkeito.dev%2Fblog%2Fa"
}
