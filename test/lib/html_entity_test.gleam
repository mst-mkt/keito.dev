import lib/html_entity

pub fn decode_named_reference_test() {
  let text = "&lt;Tips &amp; Tricks&gt;"

  let result = html_entity.decode(text)

  assert result == "<Tips & Tricks>"
}

pub fn decode_decimal_reference_test() {
  let text = "a&#8212;b"

  let result = html_entity.decode(text)

  assert result == "a—b"
}

pub fn decode_hex_reference_test() {
  let text = "a&#x2014;b"

  let result = html_entity.decode(text)

  assert result == "a—b"
}

pub fn decode_only_once_test() {
  let text = "&amp;lt;"

  let result = html_entity.decode(text)

  assert result == "&lt;"
}

pub fn keep_unknown_reference_test() {
  let text = "&copy; 2026"

  let result = html_entity.decode(text)

  assert result == "&copy; 2026"
}

pub fn keep_unterminated_reference_test() {
  let text = "AT&T & co"

  let result = html_entity.decode(text)

  assert result == "AT&T & co"
}

pub fn keep_signed_reference_test() {
  let text = "&#+65; &#x-41;"

  let result = html_entity.decode(text)

  assert result == "&#+65; &#x-41;"
}

pub fn keep_invalid_codepoint_test() {
  let text = "&#xD800;"

  let result = html_entity.decode(text)

  assert result == "&#xD800;"
}
