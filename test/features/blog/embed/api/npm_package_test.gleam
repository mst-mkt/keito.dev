import features/blog/embed/api/npm_package as api
import features/blog/embed/components/npm_package.{Package}
import gleam/json
import gleam/option.{None, Some}

const url = "https://www.npmjs.com/package/@mst-mkt/mixi2-application-sdk-ts"

pub fn decoder_test() {
  let body =
    json.object([
      #("name", json.string("@mst-mkt/mixi2-application-sdk-ts")),
      #("version", json.string("1.0.1")),
      #(
        "description",
        json.string("mixi2 Application SDK for TypeScript (Unofficial)"),
      ),
    ])
    |> json.to_string

  let result = json.parse(body, api.decoder(url, 40))

  assert result
    == Ok(Package(
      url:,
      name: "@mst-mkt/mixi2-application-sdk-ts",
      version: "1.0.1",
      description: Some("mixi2 Application SDK for TypeScript (Unofficial)"),
      downloads: 40,
    ))
}

pub fn decoder_without_description_test() {
  let body =
    json.object([
      #("name", json.string("@mst-mkt/mixi2-application-sdk-ts")),
      #("version", json.string("1.0.1")),
    ])
    |> json.to_string

  let assert Ok(Package(description:, ..)) =
    json.parse(body, api.decoder(url, 40))

  assert description == None
}
