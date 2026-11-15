import features/blog/markdown/heading

pub fn slug_test() {
  let text = "Hello, World!"

  let slug = heading.slug(text)

  assert slug == "hello-world"
}

pub fn slug_non_ascii_test() {
  let text = "Café"

  let slug = heading.slug(text)

  assert slug == "café"
}
