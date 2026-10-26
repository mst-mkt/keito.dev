import components/icons
import gleam/list
import gleam/option.{Some}
import gleam/string
import gleam/uri
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}

const brands = [
  #(["github.com"], icons.github),
  #(["twitter.com", "x.com"], icons.twitter),
  #(["discord.com", "discord.gg"], icons.discord),
  #(["mixi.social"], icons.mixi2),
  #(["bsky.app"], icons.bluesky),
  #(["dev-null.sh"], icons.dev_null),
  #(["jsr.io"], icons.jsr),
  #(["mewst.com"], icons.mewst),
  #(["twitch.tv"], icons.twitch),
  #(["zenn.dev"], icons.zenn),
]

pub fn icon(url: String) -> fn(List(Attribute(msg))) -> Element(msg) {
  let host = case uri.parse(url) {
    Ok(uri.Uri(host: Some(host), ..)) -> string.lowercase(host)
    _ -> ""
  }

  case list.find(brands, fn(brand) { list.any(brand.0, matches(host, _)) }) {
    Ok(#(_, icon)) -> icon
    Error(_) -> icons.link
  }
}

fn matches(host: String, domain: String) -> Bool {
  host == domain || string.ends_with(host, "." <> domain)
}
