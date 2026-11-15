pub fn hours(count: Int) -> Int {
  count * 60 * 60
}

pub fn days(count: Int) -> Int {
  count * hours(24)
}
