import features/blog/post.{Post}
import gleam/option.{None}
import gleam/string
import pages/index

pub fn markdown_view_test() {
  let posts = [
    Post(
      slug: "a",
      title: "A",
      emoji: "🧶",
      description: None,
      published_at: "2026-11-03",
      updated_at: None,
      event: None,
    ),
  ]

  let result = index.markdown_view(posts)

  assert string.ends_with(
    result,
    "[More links](https://keito.dev/links)\n\n- 2026-11-03 [A](https://keito.dev/blog/a)\n\n[More posts](https://keito.dev/blog)\n",
  )
}

pub fn markdown_view_without_posts_test() {
  let result = index.markdown_view([])

  assert string.ends_with(result, "[More links](https://keito.dev/links)\n")
}
