import components/icons
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/uri
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}

pub type Brand {
  GitHub
  Twitter
  Discord
  Mixi2
  Bluesky
  DevNull
  Jsr
  Mewst
  Twitch
  Zenn
}

const domains = [
  #(["github.com"], GitHub),
  #(["twitter.com", "x.com"], Twitter),
  #(["discord.com", "discord.gg"], Discord),
  #(["mixi.social"], Mixi2),
  #(["bsky.app"], Bluesky),
  #(["dev-null.sh"], DevNull),
  #(["jsr.io"], Jsr),
  #(["mewst.com"], Mewst),
  #(["twitch.tv"], Twitch),
  #(["zenn.dev"], Zenn),
]

pub fn from_url(url: String) -> Result(Brand, Nil) {
  use parsed <- result.try(uri.parse(url))
  use host <- result.try(option.to_result(parsed.host, Nil))
  let host = string.lowercase(host)

  list.find_map(domains, fn(entry) {
    case list.any(entry.0, matches(host, _)) {
      True -> Ok(entry.1)
      False -> Error(Nil)
    }
  })
}

pub fn icon(url: String) -> fn(List(Attribute(msg))) -> Element(msg) {
  case from_url(url) {
    Ok(GitHub) -> icons.github
    Ok(Twitter) -> icons.twitter
    Ok(Discord) -> icons.discord
    Ok(Mixi2) -> icons.mixi2
    Ok(Bluesky) -> icons.bluesky
    Ok(DevNull) -> icons.dev_null
    Ok(Jsr) -> icons.jsr
    Ok(Mewst) -> icons.mewst
    Ok(Twitch) -> icons.twitch
    Ok(Zenn) -> icons.zenn
    Error(_) -> icons.link
  }
}

fn matches(host: String, domain: String) -> Bool {
  host == domain || string.ends_with(host, "." <> domain)
}
