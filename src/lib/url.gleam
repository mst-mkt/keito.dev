import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/option

pub fn resolve(url: String, against base: String) -> Result(String, Nil) {
  let decoder = decode.optional(decode.at(["href"], decode.string))
  let assert Ok(resolved) = decode.run(do_parse(url, base), decoder)

  option.to_result(resolved, Nil)
}

@external(javascript, "./url.ffi.ts", "parse")
fn do_parse(url: String, base: String) -> Dynamic
