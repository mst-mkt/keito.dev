import features/blog/feed
import features/blog/post.{Post}
import gleam/option.{None, Some}

pub fn atom_test() {
  let posts = [
    Post(
      slug: "b",
      title: "B",
      emoji: "🧶",
      description: Some("B & C"),
      published_at: "2025-11-15",
      updated_at: Some("2025-12-07"),
      event: None,
    ),
    Post(
      slug: "a",
      title: "A",
      emoji: "🧶",
      description: None,
      published_at: "2025-01-01",
      updated_at: None,
      event: None,
    ),
  ]

  let atom = feed.atom(posts)

  assert atom
    == "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    <> "<feed xmlns=\"http://www.w3.org/2005/Atom\">"
    <> "<title>keito.dev</title>"
    <> "<id>https://keito.dev/blog</id>"
    <> "<link href=\"https://keito.dev/blog\"></link>"
    <> "<link href=\"https://keito.dev/blog/atom.xml\" rel=\"self\"></link>"
    <> "<updated>2025-12-07T00:00:00+09:00</updated>"
    <> "<author><name>mst-mkt</name><uri>https://keito.dev</uri></author>"
    <> "<entry>"
    <> "<title>B</title>"
    <> "<id>https://keito.dev/blog/b</id>"
    <> "<link href=\"https://keito.dev/blog/b\"></link>"
    <> "<published>2025-11-15T00:00:00+09:00</published>"
    <> "<updated>2025-12-07T00:00:00+09:00</updated>"
    <> "<summary>B &amp; C</summary>"
    <> "</entry>"
    <> "<entry>"
    <> "<title>A</title>"
    <> "<id>https://keito.dev/blog/a</id>"
    <> "<link href=\"https://keito.dev/blog/a\"></link>"
    <> "<published>2025-01-01T00:00:00+09:00</published>"
    <> "<updated>2025-01-01T00:00:00+09:00</updated>"
    <> "</entry>"
    <> "</feed>"
}
