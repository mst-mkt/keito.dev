import features/links/link.{type Link}
import gleam/bit_array
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import gleam/uri
import plinth/browser/crypto/subtle
import plinth/javascript/date

const save_endpoint = "https://pay.google.com/gp/v/save/"

// https://developers.google.com/wallet/generic/web
const max_jwt_length = 1800

pub type Error {
  InvalidKey
  TooLong
  SigningFailed(String)
}

pub fn save_url(
  issuer_id issuer_id: String,
  service_account service_account: String,
  private_key private_key: String,
  link link: Link,
) -> Promise(Result(String, Error)) {
  let issued_at = date.get_time(date.now()) / 1000
  let object = generic_object(issuer_id, link)
  let open_link = #("linksModuleData", links_module(link.url))
  let destination = #("textModulesData", text_modules(link.url))
  let candidates =
    [[open_link, destination, ..object], [destination, ..object], object]
    |> list.map(claims(issuer_id, service_account, issued_at, _))

  use key <- promise.try_await(import_key(private_key))
  use jwt <- promise.map_try(sign_fitting(key, candidates))

  Ok(save_endpoint <> jwt)
}

fn generic_object(issuer_id: String, link: Link) -> List(#(String, Json)) {
  let short_url = link.short_url(link.id)

  [
    #("id", json.string(issuer_id <> "." <> link.id)),
    #("classId", json.string(class_id(issuer_id))),
    #("state", json.string("ACTIVE")),
    #("cardTitle", localized("keito.dev")),
    #("subheader", localized("Link")),
    #("header", localized(link.name)),
    #(
      "logo",
      json.object([
        #(
          "sourceUri",
          json.object([#("uri", json.string(link.origin <> "/avatar.png"))]),
        ),
      ]),
    ),
    #("hexBackgroundColor", json.string("#1f1f1f")),
    #("barcode", qr_code(short_url)),
  ]
}

fn class_id(issuer_id: String) -> String {
  issuer_id <> ".link"
}

fn localized(value: String) -> Json {
  json.object([
    #(
      "defaultValue",
      json.object([
        #("language", json.string("en")),
        #("value", json.string(value)),
      ]),
    ),
  ])
}

fn qr_code(url: String) -> Json {
  json.object([
    #("type", json.string("QR_CODE")),
    #("value", json.string(url)),
    #("alternateText", json.string(link.display_url(url))),
  ])
}

fn links_module(url: String) -> Json {
  json.object([
    #(
      "uris",
      json.preprocessed_array([
        json.object([
          #("id", json.string("destination")),
          #("uri", json.string(url)),
          #("description", json.string("Open link")),
        ]),
      ]),
    ),
  ])
}

fn text_modules(url: String) -> Json {
  json.preprocessed_array([
    json.object([
      #("id", json.string("destination")),
      #("header", json.string("Destination")),
      #("body", json.string(host(url))),
    ]),
  ])
}

fn host(url: String) -> String {
  case uri.parse(url) {
    Ok(uri.Uri(host: Some(host), ..)) -> host
    _ -> url
  }
}

fn claims(
  issuer_id: String,
  service_account: String,
  issued_at: Int,
  object: List(#(String, Json)),
) -> Json {
  json.object([
    #("iss", json.string(service_account)),
    #("aud", json.string("google")),
    #("typ", json.string("savetowallet")),
    #("iat", json.int(issued_at)),
    #(
      "payload",
      json.object([
        #(
          "genericClasses",
          json.preprocessed_array([
            json.object([#("id", json.string(class_id(issuer_id)))]),
          ]),
        ),
        #("genericObjects", json.preprocessed_array([json.object(object)])),
      ]),
    ),
  ])
}

fn import_key(pem: String) -> Promise(Result(subtle.CryptoKey, Error)) {
  let algorithm =
    subtle.RsaHashedImportParams("RSASSA-PKCS1-v1_5", subtle.SHA256)

  case pem_to_der(pem) {
    Ok(der) ->
      subtle.import_key("pkcs8", der, algorithm, False, [subtle.Sign])
      |> promise.map(result.replace_error(_, InvalidKey))
    Error(_) -> promise.resolve(Error(InvalidKey))
  }
}

fn pem_to_der(pem: String) -> Result(BitArray, Nil) {
  case string.split(pem, "-----") {
    [_, "BEGIN PRIVATE KEY", body, "END PRIVATE KEY", ..] ->
      [" ", "\t", "\r", "\n"]
      |> list.fold(body, fn(body, space) { string.replace(body, space, "") })
      |> bit_array.base64_decode
    _ -> Error(Nil)
  }
}

fn sign_fitting(
  key: subtle.CryptoKey,
  candidates: List(Json),
) -> Promise(Result(String, Error)) {
  case candidates {
    [] -> promise.resolve(Error(TooLong))
    [claims, ..rest] -> {
      use jwt <- promise.try_await(sign(key, claims))

      case string.byte_size(jwt) > max_jwt_length {
        True -> sign_fitting(key, rest)
        False -> promise.resolve(Ok(jwt))
      }
    }
  }
}

fn sign(key: subtle.CryptoKey, claims: Json) -> Promise(Result(String, Error)) {
  let header =
    json.object([#("alg", json.string("RS256")), #("typ", json.string("JWT"))])
  let input = encode(header) <> "." <> encode(claims)

  subtle.sign(subtle.RsaSsaPkcs1v15, key, bit_array.from_string(input))
  |> promise.map(fn(signed) {
    case signed {
      Ok(signature) ->
        Ok(input <> "." <> bit_array.base64_url_encode(signature, False))
      Error(message) -> Error(SigningFailed(message))
    }
  })
}

fn encode(value: Json) -> String {
  value
  |> json.to_string
  |> bit_array.from_string
  |> bit_array.base64_url_encode(False)
}
