import features/blog/post.{Post}
import gleam/option.{None}
import pages/blog

pub fn markdown_view_test() {
  let posts = [
    Post(
      slug: "b",
      title: "B",
      emoji: "🧶",
      description: None,
      published_at: "2025-11-15",
      updated_at: None,
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

  let result = blog.markdown_view(posts)

  assert result
    == "# Blog\n\n- 2025-11-15 [B](https://keito.dev/blog/b)\n- 2025-01-01 [A](https://keito.dev/blog/a)\n"
}

pub fn markdown_view_without_posts_test() {
  let result = blog.markdown_view([])

  assert result == "# Blog\n\nNo posts.\n"
}
