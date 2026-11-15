import features/blog/embed/api/cache
import features/blog/embed/api/remote
import features/blog/embed/components/link_card.{type LinkCard, LinkCard}
import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/fetch.{type FetchBody}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri
import lib/html_entity
import lib/html_head.{type Head, type Link, type Meta}
import lib/url
import server/context.{type Context}

pub fn fetch(context: Context, url: String) -> Promise(Result(LinkCard, Nil)) {
  use body <- promise.map(
    cache.get(context, "link_card:" <> url, fn() { remote.get(url, read_head) }),
  )

  cache.parse(body, decoder(url))
}

fn read_head(response: Response(FetchBody)) -> Promise(Result(String, Nil)) {
  use head <- promise.map(html_head.read(response.body))

  Ok(encode_head(head))
}

@internal
pub fn encode_head(head: Head) -> String {
  let base = case head.base {
    Some(base) -> [#("base", base)]
    None -> []
  }
  let titles =
    list.map(head.titles, fn(title) { #("title", string.trim(title)) })
  let metas = list.filter_map(head.metas, meta_pair)
  let icons = list.filter_map(head.links, icon_pair)

  list.flatten([base, titles, metas, icons])
  |> list.filter(fn(pair) { pair.1 != "" })
  |> json.array(fn(pair) {
    json.preprocessed_array([json.string(pair.0), json.string(pair.1)])
  })
  |> json.to_string
}

fn meta_pair(meta: Meta) -> Result(#(String, String), Nil) {
  use name <- result.try(
    option.or(meta.property, meta.name) |> option.to_result(Nil),
  )
  use content <- result.map(option.to_result(meta.content, Nil))

  #(string.lowercase(name), content)
}

fn icon_pair(link: Link) -> Result(#(String, String), Nil) {
  use rel <- result.try(option.to_result(link.rel, Nil))
  use <- bool.guard(
    !list.contains(string.split(string.lowercase(rel), " "), "icon"),
    Error(Nil),
  )
  use href <- result.map(option.to_result(link.href, Nil))

  #("icon", href)
}

@internal
pub fn decoder(url: String) -> Decoder(LinkCard) {
  use pairs <- decode.then(decode.list(pair_decoder()))
  let find = fn(names) {
    list.find_map(names, fn(name) {
      list.key_find(pairs, name) |> result.map(html_entity.decode)
    })
    |> option.from_result
  }
  let base =
    find(["base"]) |> option.then(resolve(url, _)) |> option.unwrap(url)

  decode.success(LinkCard(
    url:,
    title: find(["og:title", "twitter:title", "title"]) |> option.unwrap(url),
    description: find(["og:description", "twitter:description", "description"]),
    image: find(["og:image", "twitter:image"]) |> option.then(resolve(base, _)),
    site: find(["og:site_name"]) |> option.unwrap(host(url)),
    icon: find(["icon"]) |> option.then(resolve(base, _)),
  ))
}

fn pair_decoder() -> Decoder(#(String, String)) {
  use name <- decode.field(0, decode.string)
  use value <- decode.field(1, decode.string)

  decode.success(#(name, value))
}

fn resolve(base: String, relative: String) -> Option(String) {
  url.resolve(relative, against: base) |> option.from_result
}

fn host(url: String) -> String {
  case uri.parse(url) {
    Ok(uri.Uri(host: Some(host), ..)) -> host
    _ -> url
  }
}
