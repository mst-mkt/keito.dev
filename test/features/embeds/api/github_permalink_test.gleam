import features/embeds/api/github_permalink as api
import features/embeds/components/github_permalink.{Range, WholeFile}

pub fn select_range_test() {
  let text = "a\nb\nc\nd\n"

  let result = api.select(text, Range(2, 3))

  assert result == Ok(#("a\nb\nc", 1))
}

pub fn select_range_beyond_file_test() {
  let text = "a\nb\n"

  let result = api.select(text, Range(3, 3))

  assert result == Error(Nil)
}

pub fn select_whole_file_test() {
  let text = "a\nb\n"

  let result = api.select(text, WholeFile)

  assert result == Ok(#("a\nb", 0))
}

pub fn language_alias_test() {
  let path = "lib/Foo.pm"

  let language = api.language(path)

  assert language == "perl"
}

pub fn language_without_extension_test() {
  let path = "v1.2/Makefile"

  let language = api.language(path)

  assert language == ""
}
