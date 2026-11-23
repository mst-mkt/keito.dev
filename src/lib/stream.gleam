import gleam/fetch.{type FetchBody}
import hinoto/body.{type JsReadableStream}

@external(javascript, "./stream.ffi.ts", "fromFetchBody")
pub fn from_fetch_body(body: FetchBody) -> JsReadableStream
