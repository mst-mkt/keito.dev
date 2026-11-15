import lib/md

pub fn link_escape_test() {
  let text = "a [b] \\c"

  let result = md.link(text, "https://example.com/")

  assert result == "[a \\[b\\] \\\\c](https://example.com/)"
}
