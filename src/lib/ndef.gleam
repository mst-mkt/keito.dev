import gleam/javascript/promise.{type Promise}

pub type Reader

@external(javascript, "./ndef.ffi.ts", "reader")
pub fn reader() -> Result(Reader, Nil)

@external(javascript, "./ndef.ffi.ts", "writeUrl")
pub fn write_url(reader: Reader, url: String) -> Promise(Nil)
