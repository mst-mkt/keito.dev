import features/links/link.{Draft, Errors, Link}
import gleam/option.{None, Some}
import gleam/string

pub fn parse_id_normalization_test() {
  let input = "  My-Link_v1.2 "

  let result = link.parse_id(input)

  assert result == Ok("my-link_v1.2")
}

pub fn parse_id_empty_test() {
  let input = "   "

  let result = link.parse_id(input)

  assert result == Error("ID is required.")
}

pub fn parse_id_invalid_characters_test() {
  let input = "my link"

  let result = link.parse_id(input)

  assert result
    == Error("ID can only contain a-z, 0-9, \"-\", \"_\", and \".\".")
}

pub fn parse_id_reserved_test() {
  let input = "new"

  let result = link.parse_id(input)

  assert result == Error("\"new\" is a reserved ID.")
}

pub fn parse_url_non_http_scheme_test() {
  let input = "javascript:alert(1)"

  let result = link.parse_url(input)

  assert result == Error("URL must be an absolute http(s) URL.")
}

pub fn parse_url_missing_scheme_test() {
  let input = "example.com/path"

  let result = link.parse_url(input)

  assert result == Error("URL must be an absolute http(s) URL.")
}

pub fn parse_url_percent_encoding_test() {
  let input = " https://example.com/a b/日本 "

  let result = link.parse_url(input)

  assert result == Ok("https://example.com/a%20b/%E6%97%A5%E6%9C%AC")
}

pub fn parse_url_length_limit_test() {
  let prefix = "https://example.com/"
  let at_limit = prefix <> string.repeat("a", 600 - string.length(prefix))
  let over_limit = at_limit <> "a"

  let accepted = link.parse_url(at_limit)
  let rejected = link.parse_url(over_limit)

  assert accepted == Ok(at_limit)
  assert rejected == Error("URL is too long.")
}

pub fn parse_default_name_test() {
  let draft = Draft(id: "github", name: " ", url: "https://github.com")

  let result = link.parse(draft)

  assert result
    == Ok(Link(id: "github", name: "github", url: "https://github.com"))
}

pub fn parse_name_length_limit_test() {
  let draft =
    Draft(id: "a", name: string.repeat("あ", 81), url: "https://example.com")

  let result = link.parse(draft)

  assert result
    == Error(Errors(..link.no_errors, name: Some("Name is too long.")))
}

pub fn parse_all_field_errors_test() {
  let draft = Draft(id: "", name: "", url: "")

  let result = link.parse(draft)

  assert result
    == Error(Errors(
      id: Some("ID is required."),
      name: None,
      url: Some("URL must be an absolute http(s) URL."),
    ))
}

pub fn display_url_scheme_and_trailing_slash_test() {
  let url = "https://example.com/path/"

  let result = link.display_url(url)

  assert result == "example.com/path"
}

pub fn display_url_percent_decoding_test() {
  let url = "https://example.com/%E6%97%A5%E6%9C%AC"

  let result = link.display_url(url)

  assert result == "example.com/日本"
}
