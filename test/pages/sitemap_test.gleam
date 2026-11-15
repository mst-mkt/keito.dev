import features/blog/post.{Post}
import gleam/option.{None, Some}
import pages/sitemap

pub fn xml_test() {
  let posts = [
    Post(
      slug: "b",
      title: "B",
      emoji: "🧶",
      description: None,
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

  let xml = sitemap.xml(posts)

  assert xml
    == "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    <> "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
    <> "<url><loc>https://keito.dev/</loc></url>"
    <> "<url><loc>https://keito.dev/blog</loc></url>"
    <> "<url><loc>https://keito.dev/links</loc></url>"
    <> "<url><loc>https://keito.dev/blog/b</loc><lastmod>2025-12-07</lastmod></url>"
    <> "<url><loc>https://keito.dev/blog/a</loc><lastmod>2025-01-01</lastmod></url>"
    <> "</urlset>"
}
