import features/embeds/api/cache
import features/embeds/api/remote
import features/embeds/components/npm_package.{type Package, Package}
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/promise.{type Promise}
import gleam/option.{None}
import gleam/result
import server/context.{type Context}

pub fn fetch(
  context: Context,
  url: String,
  name: String,
) -> Promise(Result(Package, Nil)) {
  let latest_api = "https://registry.npmjs.org/" <> name <> "/latest"
  let downloads_api = "https://api.npmjs.org/downloads/point/last-week/" <> name
  let latest =
    cache.get(context, "npm_package:" <> name, fn() {
      remote.get(latest_api, remote.read_text)
    })
  let downloads =
    cache.get(context, "npm_downloads:" <> name, fn() {
      remote.get(downloads_api, remote.read_text)
    })

  use latest <- promise.await(latest)
  use downloads <- promise.map(downloads)
  use count <- result.try(cache.parse(
    downloads,
    decode.at(["downloads"], decode.int),
  ))

  cache.parse(latest, decoder(url, count))
}

@internal
pub fn decoder(url: String, downloads: Int) -> Decoder(Package) {
  use name <- decode.field("name", decode.string)
  use version <- decode.field("version", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )

  decode.success(Package(url:, name:, version:, description:, downloads:))
}
