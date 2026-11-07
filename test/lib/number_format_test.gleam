import lib/number_format

pub fn compact_below_thousand_test() {
  let result = number_format.compact(999)

  assert result == "999"
}

pub fn compact_thousands_test() {
  let result = number_format.compact(52_300)

  assert result == "52.3k"
}

pub fn compact_millions_test() {
  let result = number_format.compact(1_234_567)

  assert result == "1.2M"
}

pub fn compact_without_tenth_test() {
  let result = number_format.compact(1000)

  assert result == "1k"
}

pub fn compact_truncates_test() {
  let result = number_format.compact(999_999)

  assert result == "999.9k"
}
