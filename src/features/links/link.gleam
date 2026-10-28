import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri

pub type Link {
  Link(id: String, name: String, url: String)
}

pub type Draft {
  Draft(id: String, name: String, url: String)
}

pub type Errors {
  Errors(id: Option(String), name: Option(String), url: Option(String))
}

pub const empty_draft = Draft(id: "", name: "", url: "")

pub const no_errors = Errors(id: None, name: None, url: None)

pub const list_path = "/links"

pub const new_path = "/links/new"

pub const origin = "https://keito.dev"

const id_characters = "abcdefghijklmnopqrstuvwxyz0123456789-_."

const reserved_ids = ["new", ".", ".."]

const unsafe_characters = " \"<>\\^`{|}"

pub fn page_path(id: String) -> String {
  list_path <> "/" <> id
}

pub fn edit_path(id: String) -> String {
  page_path(id) <> "/edit"
}

pub fn delete_path(id: String) -> String {
  page_path(id) <> "/delete"
}

pub fn wallet_path(id: String) -> String {
  page_path(id) <> "/wallet"
}

pub fn redirect_path(id: String) -> String {
  "/l/" <> id
}

pub fn short_url(id: String) -> String {
  origin <> redirect_path(id)
}

pub fn display_url(url: String) -> String {
  let url = case result.unwrap(uri.percent_decode(url), url) {
    "https://" <> rest | "http://" <> rest -> rest
    decoded -> decoded
  }

  case string.ends_with(url, "/") {
    True -> string.drop_end(url, 1)
    False -> url
  }
}

pub fn normalize_id(id: String) -> String {
  id |> string.trim |> string.lowercase
}

pub fn to_draft(link: Link) -> Draft {
  Draft(id: link.id, name: link.name, url: link.url)
}

pub fn parse(draft: Draft) -> Result(Link, Errors) {
  case parse_id(draft.id), parse_name(draft.name), parse_url(draft.url) {
    Ok(id), Ok(""), Ok(url) -> Ok(Link(id:, name: id, url:))
    Ok(id), Ok(name), Ok(url) -> Ok(Link(id:, name:, url:))
    id, name, url ->
      Error(Errors(id: error(id), name: error(name), url: error(url)))
  }
}

pub fn taken(id: String) -> Errors {
  Errors(..no_errors, id: Some("\"" <> id <> "\" is already used."))
}

pub fn parse_id(id: String) -> Result(String, String) {
  let id = normalize_id(id)
  let valid =
    id
    |> string.to_graphemes
    |> list.all(string.contains(id_characters, _))

  case id, valid, list.contains(reserved_ids, id) {
    "", _, _ -> Error("ID is required.")
    _, False, _ ->
      Error("ID can only contain a-z, 0-9, \"-\", \"_\", and \".\".")
    _, _, True -> Error("\"" <> id <> "\" is a reserved ID.")
    _, True, False -> Ok(id)
  }
}

pub fn parse_url(url: String) -> Result(String, String) {
  let url = url |> string.trim |> encode_unsafe_characters

  case uri.parse(url), string.byte_size(url) > 600 {
    _, True -> Error("URL is too long.")
    Ok(uri.Uri(scheme: Some("http"), host: Some(host), ..)), False
    | Ok(uri.Uri(scheme: Some("https"), host: Some(host), ..)), False
      if host != ""
    -> Ok(url)
    _, _ -> Error("URL must be an absolute http(s) URL.")
  }
}

fn encode_unsafe_characters(url: String) -> String {
  url
  |> string.to_graphemes
  |> list.map(fn(char) {
    let ascii = string.byte_size(char) == 1

    case ascii && !string.contains(unsafe_characters, char) {
      True -> char
      False -> uri.percent_encode(char)
    }
  })
  |> string.concat
}

fn parse_name(name: String) -> Result(String, String) {
  let name = string.trim(name)

  case string.length(name) > 80 {
    True -> Error("Name is too long.")
    False -> Ok(name)
  }
}

fn error(result: Result(a, String)) -> Option(String) {
  case result {
    Ok(_) -> None
    Error(message) -> Some(message)
  }
}
