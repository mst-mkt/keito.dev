import lib/url

pub fn resolve_test() {
  let result = url.resolve("../c", against: "https://example.com/a/b")

  assert result == Ok("https://example.com/c")
}

pub fn resolve_against_relative_base_test() {
  let result = url.resolve("../c", against: "/a/b")

  assert result == Error(Nil)
}
