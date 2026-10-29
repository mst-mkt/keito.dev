import gleam/string
import lib/terminal

pub fn document_test() {
  let sections = [["a", "b"], ["c"]]

  let result = terminal.document(sections)

  assert result == "\n  a\n  b\n\n  c\n\n"
}

pub fn document_blank_line_test() {
  let sections = [["a", "", "b"]]

  let result = terminal.document(sections)

  assert result == "\n  a\n\n  b\n\n"
}

pub fn document_empty_sections_test() {
  let sections = [["a"], [], ["b"]]

  let result = terminal.document(sections)

  assert result == "\n  a\n\n  b\n\n"
}

pub fn paragraph_test() {
  let word = string.repeat("a", terminal.columns / 2)
  let lines = ["a", word <> " " <> word <> " b"]

  let result = terminal.paragraph(lines)

  assert result == ["a", word <> " " <> word, "b"]
}

pub fn wrap_test() {
  let word = string.repeat("a", terminal.columns / 2)
  let text = word <> " " <> word <> " b"

  let result = terminal.wrap(text)

  assert result == [word <> " " <> word, "b"]
}

pub fn wrap_escape_sequences_test() {
  let url = "https://example.com/" <> string.repeat("a", terminal.columns)
  let text = "a " <> terminal.link("b", url)

  let result = terminal.wrap(text)

  assert result == [text]
}

pub fn table_test() {
  let rows = [["a", "bb", "c"], ["ccc", "d", "e"]]

  let result = terminal.table(rows)

  assert result == ["a     bb   c", "ccc   d    e"]
}

pub fn table_uneven_rows_test() {
  let rows = [["a", "b", "c"], ["dd"]]

  let result = terminal.table(rows)

  assert result == ["a    b   c", "dd"]
}

pub fn table_escape_sequences_test() {
  let styled = terminal.bold(terminal.link("a", "https://example.com"))
  let rows = [[styled, "x"], ["abc", "y"]]

  let result = terminal.table(rows)

  assert result == [styled <> "     x", "abc   y"]
}

pub fn table_bel_terminated_osc_test() {
  let link = "\u{001b}]8;;https://example.com\u{0007}a\u{001b}]8;;\u{0007}"
  let rows = [[link, "x"], ["abc", "y"]]

  let result = terminal.table(rows)

  assert result == [link <> "     x", "abc   y"]
}

pub fn table_wide_characters_test() {
  let rows = [["あい", "x"], ["abcde", "y"]]

  let result = terminal.table(rows)

  assert result == ["あい    x", "abcde   y"]
}

pub fn table_zero_width_characters_test() {
  let rows = [["e\u{0301}", "x"], ["ab", "y"]]

  let result = terminal.table(rows)

  assert result == ["e\u{0301}    x", "ab   y"]
}

pub fn beside_test() {
  let left = ["ab", "abcd"]
  let right = ["", "x", "y"]

  let result = terminal.beside(left, right)

  assert result == ["ab", "abcd   x", "       y"]
}

pub fn leader_test() {
  let dashes = string.repeat("-", terminal.columns - 5)

  let result = terminal.leader("ab", "c")

  assert result == "ab " <> terminal.dim(dashes) <> " c"
}

pub fn leader_overflow_test() {
  let left = string.repeat("a", terminal.columns)

  let result = terminal.leader(left, "b")

  assert result == left <> " " <> terminal.dim("-") <> " b"
}
