import features/embeds/api/cache
import features/embeds/api/remote.{Failed, Found, Gone}
import gleam/dynamic.{type Dynamic}

fn metadata(fetched_at: String) -> Dynamic {
  dynamic.properties([
    #(dynamic.string("fetched_at"), dynamic.string(fetched_at)),
  ])
}

pub fn is_stale_fresh_test() {
  let metadata = metadata("1000")

  let result = cache.is_stale(metadata, at: 1000 + 24 * 60 * 60)

  assert result == False
}

pub fn is_stale_old_test() {
  let metadata = metadata("1000")

  let result = cache.is_stale(metadata, at: 1000 + 24 * 60 * 60 + 1)

  assert result == True
}

pub fn is_stale_without_fetched_at_test() {
  let metadata = dynamic.nil()

  let result = cache.is_stale(metadata, at: 1000)

  assert result == True
}

pub fn entry_found_test() {
  let result = cache.entry(Found("{}"), cached: True)

  assert result == Ok(#("{}", 30 * 24 * 60 * 60))
}

pub fn entry_gone_test() {
  let result = cache.entry(Gone, cached: True)

  assert result == Ok(#("", 30 * 24 * 60 * 60))
}

pub fn entry_failed_without_cache_test() {
  let result = cache.entry(Failed, cached: False)

  assert result == Ok(#("", 60 * 60))
}

pub fn entry_failed_with_cache_test() {
  let result = cache.entry(Failed, cached: True)

  assert result == Error(Nil)
}
