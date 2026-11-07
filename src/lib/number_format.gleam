import gleam/int

pub fn compact(value: Int) -> String {
  case value {
    _ if value >= 1_000_000 -> with_unit(value, 1_000_000, "M")
    _ if value >= 1000 -> with_unit(value, 1000, "k")
    _ -> int.to_string(value)
  }
}

fn with_unit(value: Int, unit: Int, suffix: String) -> String {
  let whole = int.to_string(value / unit)

  case value * 10 / unit % 10 {
    0 -> whole <> suffix
    tenth -> whole <> "." <> int.to_string(tenth) <> suffix
  }
}
