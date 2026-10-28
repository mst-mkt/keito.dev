import features/links/link.{Link}
import features/links/wallet
import gleam/bit_array
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import plinth/browser/crypto/subtle

const issuer_id = "3388000000000000000"

const service_account = "wallet-issuer@example.iam.gserviceaccount.com"

const github =
  Link(id: "github", name: "GitHub", url: "https://github.com/mst-mkt")

type Pass {
  Pass(
    service_account: String,
    class_ids: List(String),
    id: String,
    class_id: String,
    name: String,
    qr_code: String,
    destination: Option(String),
    url: Option(String),
  )
}

pub fn save_url_signature_test() {
  use #(der, public_key) <- promise.await(generate_key())
  let private_key = pem("PRIVATE KEY", der, "\n")

  use result <- promise.await(wallet.save_url(
    issuer_id:,
    service_account:,
    private_key:,
    link: github,
  ))

  let assert [header, payload, signature] = string.split(jwt(result), ".")
  let assert Ok(signature) = bit_array.base64_url_decode(signature)
  use verified <- promise.map(subtle.verify(
    subtle.RsaSsaPkcs1v15,
    public_key,
    signature,
    bit_array.from_string(header <> "." <> payload),
  ))
  assert verified == Ok(True)
}

pub fn save_url_object_test() {
  use #(der, _) <- promise.await(generate_key())
  let private_key = pem("PRIVATE KEY", der, "\n")

  use result <- promise.map(wallet.save_url(
    issuer_id:,
    service_account:,
    private_key:,
    link: github,
  ))

  assert pass(result)
    == Pass(
      service_account: "wallet-issuer@example.iam.gserviceaccount.com",
      class_ids: ["3388000000000000000.link"],
      id: "3388000000000000000.github",
      class_id: "3388000000000000000.link",
      name: "GitHub",
      qr_code: "https://keito.dev/l/github",
      destination: Some("github.com"),
      url: Some("https://github.com/mst-mkt"),
    )
}

pub fn save_url_long_url_fallback_test() {
  use #(der, _) <- promise.await(generate_key())
  let private_key = pem("PRIVATE KEY", der, "\n")
  let prefix = "https://example.com/"
  let url = prefix <> string.repeat("a", 600 - string.length(prefix))
  let link = Link(id: "example", name: "Example", url:)

  use result <- promise.map(wallet.save_url(
    issuer_id:,
    service_account:,
    private_key:,
    link:,
  ))

  assert string.byte_size(jwt(result)) <= 1800
  assert pass(result).destination == Some("example.com")
  assert pass(result).url == None
}

pub fn save_url_long_name_fallback_test() {
  use #(der, _) <- promise.await(generate_key())
  let private_key = pem("PRIVATE KEY", der, "\n")
  let prefix = "https://example.com/"
  let url = prefix <> string.repeat("a", 600 - string.length(prefix))
  let link = Link(id: "example", name: string.repeat("🔗", 80), url:)

  use result <- promise.map(wallet.save_url(
    issuer_id:,
    service_account:,
    private_key:,
    link:,
  ))

  assert string.byte_size(jwt(result)) <= 1800
  assert pass(result).name == string.repeat("🔗", 80)
  assert pass(result).destination == None
  assert pass(result).url == None
}

pub fn save_url_too_long_test() {
  use #(der, _) <- promise.await(generate_key())
  let private_key = pem("PRIVATE KEY", der, "\n")
  let link =
    Link(
      id: string.repeat("a", 200),
      name: string.repeat("🔗", 80),
      url: "https://example.com",
    )

  use result <- promise.map(wallet.save_url(
    issuer_id:,
    service_account:,
    private_key:,
    link:,
  ))

  assert result == Error(wallet.TooLong)
}

pub fn save_url_crlf_key_test() {
  use #(der, _) <- promise.await(generate_key())
  let private_key = pem("PRIVATE KEY", der, "\r\n")

  use result <- promise.map(wallet.save_url(
    issuer_id:,
    service_account:,
    private_key:,
    link: github,
  ))

  let assert Ok(_) = result
}

pub fn save_url_rsa_private_key_label_test() {
  use #(der, _) <- promise.await(generate_key())
  let private_key = pem("RSA PRIVATE KEY", der, "\n")

  use result <- promise.map(wallet.save_url(
    issuer_id:,
    service_account:,
    private_key:,
    link: github,
  ))

  assert result == Error(wallet.InvalidKey)
}

fn generate_key() -> Promise(#(BitArray, subtle.CryptoKey)) {
  let algorithm =
    subtle.RsaHashedKeyGenParams(
      name: "RSASSA-PKCS1-v1_5",
      modulus_length: 2048,
      public_exponent: <<1, 0, 1>>,
      hash: subtle.SHA256,
    )
  use generated <- promise.await(
    subtle.generate_key(algorithm, True, [subtle.Sign, subtle.Verify]),
  )
  let assert Ok(#(public_key, private_key)) = generated
  use exported <- promise.map(subtle.export(private_key, subtle.Pkcs8))
  let assert Ok(der) = exported

  #(der, public_key)
}

fn pem(label: String, der: BitArray, newline: String) -> String {
  let body =
    bit_array.base64_encode(der, True)
    |> string.to_graphemes
    |> list.sized_chunk(64)
    |> list.map(string.concat)

  ["-----BEGIN " <> label <> "-----", ..body]
  |> list.append(["-----END " <> label <> "-----", ""])
  |> string.join(newline)
}

fn jwt(result: Result(String, wallet.Error)) -> String {
  let assert Ok("https://pay.google.com/gp/v/save/" <> jwt) = result

  jwt
}

fn pass(result: Result(String, wallet.Error)) -> Pass {
  let object = fn(service_account, class_ids) {
    use id <- decode.field("id", decode.string)
    use class_id <- decode.field("classId", decode.string)
    use name <- decode.subfield(
      ["header", "defaultValue", "value"],
      decode.string,
    )
    use qr_code <- decode.subfield(["barcode", "value"], decode.string)
    use destination <- decode.optional_field(
      "textModulesData",
      None,
      decode.at([0], decode.at(["body"], decode.string)) |> decode.map(Some),
    )
    use url <- decode.optional_field(
      "linksModuleData",
      None,
      decode.at(["uris"], decode.at([0], decode.at(["uri"], decode.string)))
        |> decode.map(Some),
    )
    decode.success(Pass(
      service_account:,
      class_ids:,
      id:,
      class_id:,
      name:,
      qr_code:,
      destination:,
      url:,
    ))
  }
  let decoder = {
    use service_account <- decode.field("iss", decode.string)
    use class_ids <- decode.subfield(
      ["payload", "genericClasses"],
      decode.list(decode.at(["id"], decode.string)),
    )
    use pass <- decode.subfield(
      ["payload", "genericObjects"],
      decode.at([0], object(service_account, class_ids)),
    )
    decode.success(pass)
  }

  let assert [_, payload, _] = string.split(jwt(result), ".")
  let assert Ok(payload) = bit_array.base64_url_decode(payload)
  let assert Ok(payload) = bit_array.to_string(payload)
  let assert Ok(pass) = json.parse(payload, decoder)

  pass
}
