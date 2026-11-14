import gleam/fetch.{type FetchRequest, type FetchResponse}
import gleam/javascript/promise.{type Promise}

pub type Service

@external(javascript, "./service.ffi.ts", "fetch")
pub fn fetch(service: Service, request: FetchRequest) -> Promise(FetchResponse)
