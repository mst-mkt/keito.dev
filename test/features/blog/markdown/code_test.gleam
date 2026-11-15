import features/blog/markdown/code

pub fn language_test() {
  let info = "ts title=\"index.ts\""

  let language = code.language(info)

  assert language == "ts"
}
