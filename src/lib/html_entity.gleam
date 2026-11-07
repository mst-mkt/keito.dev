import gleam/int
import gleam/result
import gleam/string

pub fn decode(text: String) -> String {
  case string.split_once(text, "&") {
    Ok(#(before, after)) -> before <> decode_reference(after)
    Error(Nil) -> text
  }
}

fn decode_reference(text: String) -> String {
  let decoded = {
    use #(name, rest) <- result.try(string.split_once(text, ";"))
    use character <- result.map(character(name))

    #(character, rest)
  }

  case decoded {
    Ok(#(character, rest)) -> character <> decode(rest)
    Error(Nil) -> "&" <> decode(text)
  }
}

fn character(name: String) -> Result(String, Nil) {
  case name {
    "amp" -> Ok("&")
    "lt" -> Ok("<")
    "gt" -> Ok(">")
    "quot" -> Ok("\"")
    "apos" -> Ok("'")
    "nbsp" -> Ok("\u{a0}")
    "#x" <> digits | "#X" <> digits ->
      unsigned(digits, int.base_parse(_, 16)) |> result.try(codepoint)
    "#" <> digits -> unsigned(digits, int.parse) |> result.try(codepoint)
    _ -> Error(Nil)
  }
}

fn unsigned(
  digits: String,
  parse: fn(String) -> Result(Int, Nil),
) -> Result(Int, Nil) {
  case digits {
    "+" <> _ | "-" <> _ -> Error(Nil)
    digits -> parse(digits)
  }
}

fn codepoint(value: Int) -> Result(String, Nil) {
  string.utf_codepoint(value)
  |> result.map(fn(codepoint) { string.from_utf_codepoints([codepoint]) })
}
