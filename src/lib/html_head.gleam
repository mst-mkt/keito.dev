import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/fetch.{type FetchBody}
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option}

pub type Head {
  Head(
    base: Option(String),
    titles: List(String),
    metas: List(Meta),
    links: List(Link),
  )
}

pub type Meta {
  Meta(name: Option(String), property: Option(String), content: Option(String))
}

pub type Link {
  Link(rel: Option(String), href: Option(String))
}

pub fn read(body: FetchBody) -> Promise(Head) {
  use head <- promise.map(do_read(body))
  let assert Ok(head) = decode.run(head, head_decoder())

  head
}

fn head_decoder() -> Decoder(Head) {
  use base <- decode.field("base", decode.optional(decode.string))
  use titles <- decode.field("titles", decode.list(decode.string))
  use metas <- decode.field("metas", decode.list(meta_decoder()))
  use links <- decode.field("links", decode.list(link_decoder()))

  decode.success(Head(base:, titles:, metas:, links:))
}

fn meta_decoder() -> Decoder(Meta) {
  use name <- decode.field("name", decode.optional(decode.string))
  use property <- decode.field("property", decode.optional(decode.string))
  use content <- decode.field("content", decode.optional(decode.string))

  decode.success(Meta(name:, property:, content:))
}

fn link_decoder() -> Decoder(Link) {
  use rel <- decode.field("rel", decode.optional(decode.string))
  use href <- decode.field("href", decode.optional(decode.string))

  decode.success(Link(rel:, href:))
}

@external(javascript, "./html_head.ffi.ts", "read")
fn do_read(body: FetchBody) -> Promise(Dynamic)
