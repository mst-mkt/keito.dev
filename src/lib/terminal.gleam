import gleam/int
import gleam/list
import gleam/string

type Mode {
  Text
  Escape
  Csi
  Osc
}

pub const columns = 65

const indent = 2

const gap = 3

const esc = "\u{001b}"

const zero_width = [#(0x0300, 0x036f), #(0x200b, 0x200f), #(0xfe00, 0xfe0f)]

const wide = [
  #(0x1100, 0x115f),
  #(0x2e80, 0xa4cf),
  #(0xac00, 0xd7a3),
  #(0xf900, 0xfaff),
  #(0xfe30, 0xfe4f),
  #(0xff00, 0xff60),
  #(0xffe0, 0xffe6),
  #(0x1f300, 0x1faff),
  #(0x20000, 0x3fffd),
]

pub fn document(sections: List(List(String))) -> String {
  let body =
    sections
    |> list.filter(fn(lines) { lines != [] })
    |> list.map(fn(lines) {
      lines |> list.map(indent_line) |> string.join("\n")
    })
    |> string.join("\n\n")

  "\n" <> body <> "\n\n"
}

pub fn paragraph(lines: List(String)) -> List(String) {
  list.flat_map(lines, wrap)
}

pub fn wrap(text: String) -> List(String) {
  let assert [first, ..words] = string.split(text, " ")
    as "string.split always returns at least one element"

  let #(lines, line) =
    list.fold(words, #([], first), fn(state, word) {
      let #(lines, line) = state

      case width(line) + 1 + width(word) > columns {
        True -> #([line, ..lines], word)
        False -> #(lines, line <> " " <> word)
      }
    })

  list.reverse([line, ..lines])
}

pub fn table(rows: List(List(String))) -> List(String) {
  let widths = rows |> list.transpose |> list.map(max_width)

  list.map(rows, fn(row) {
    list.map2(row, widths, pad)
    |> string.join(spaces(gap))
    |> string.trim_end
  })
}

pub fn beside(left: List(String), right: List(String)) -> List(String) {
  let height = int.max(list.length(left), list.length(right))
  let fill = fn(lines) {
    list.append(lines, list.repeat("", height - list.length(lines)))
  }

  list.map2(fill(left), fill(right), fn(left, right) { [left, right] })
  |> table
}

pub fn leader(left: String, right: String) -> String {
  let dashes = int.max(columns - width(left) - width(right) - 2, 1)

  left <> " " <> dim(string.repeat("-", dashes)) <> " " <> right
}

pub fn bold(text: String) -> String {
  sgr(text, "1", "22")
}

pub fn dim(text: String) -> String {
  sgr(text, "2", "22")
}

pub fn underline(text: String) -> String {
  sgr(text, "4", "24")
}

pub fn link(text: String, url: String) -> String {
  hyperlink(url) <> text <> hyperlink("")
}

fn sgr(text: String, on: String, off: String) -> String {
  esc <> "[" <> on <> "m" <> text <> esc <> "[" <> off <> "m"
}

fn hyperlink(url: String) -> String {
  esc <> "]8;;" <> url <> esc <> "\\"
}

fn spaces(count: Int) -> String {
  string.repeat(" ", count)
}

fn indent_line(line: String) -> String {
  case line {
    "" -> ""
    _ -> spaces(indent) <> line
  }
}

fn pad(text: String, to: Int) -> String {
  text <> spaces(to - width(text))
}

fn max_width(lines: List(String)) -> Int {
  list.fold(lines, 0, fn(max, line) { int.max(max, width(line)) })
}

fn width(text: String) -> Int {
  let #(total, _) =
    text
    |> string.to_utf_codepoints
    |> list.fold(#(0, Text), fn(state, codepoint) {
      let #(total, mode) = state

      case mode, string.utf_codepoint_to_int(codepoint) {
        Text, 0x1b -> #(total, Escape)
        Text, code -> #(total + codepoint_width(code), Text)
        Escape, 0x5b -> #(total, Csi)
        Escape, 0x5d -> #(total, Osc)
        Escape, _ -> #(total, Text)
        Csi, code if code >= 0x40 && code <= 0x7e -> #(total, Text)
        Csi, _ -> #(total, Csi)
        Osc, 0x1b -> #(total, Escape)
        Osc, 0x07 -> #(total, Text)
        Osc, _ -> #(total, Osc)
      }
    })

  total
}

fn codepoint_width(code: Int) -> Int {
  let within = fn(ranges) {
    list.any(ranges, fn(range: #(Int, Int)) {
      code >= range.0 && code <= range.1
    })
  }

  case within(zero_width), within(wide) {
    True, _ -> 0
    False, True -> 2
    False, False -> 1
  }
}
