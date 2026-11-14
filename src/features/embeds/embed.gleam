import components/text_link
import features/embeds/api/github_repository as github_repository_api
import features/embeds/api/link_card as link_card_api
import features/embeds/api/npm_package as npm_package_api
import features/embeds/api/slide as slide_api
import features/embeds/api/tweet as tweet_api
import features/embeds/components/github_repository
import features/embeds/components/link_card
import features/embeds/components/npm_package
import features/embeds/components/slide
import features/embeds/components/tweet
import gleam/bool
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import gleam/uri
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}

pub type Embed {
  LinkCard(url: String)
  GitHubRepository(url: String, owner: String, repo: String)
  Tweet(url: String, id: String)
  SpeakerDeck(url: String)
  Docswell(url: String)
  NpmPackage(url: String, name: String)
}

const tags = [
  "LinkCard", "GitHubRepository", "Tweet", "SpeakerDeck", "Docswell",
  "NpmPackage",
]

pub fn from_tag(
  tag: String,
  attributes: List(#(String, String)),
) -> Result(Embed, String) {
  let element = "<" <> tag <> ">"
  use <- bool.guard(
    !list.contains(tags, tag),
    Error(element <> " is not an embed."),
  )
  use url <- result.try(
    list.key_find(attributes, "url")
    |> result.replace_error(element <> " requires a url attribute."),
  )

  {
    use #(host, path) <- result.try(host_and_path(url))

    parse(tag, url, host, path)
  }
  |> result.replace_error(element <> " does not support " <> url <> ".")
}

fn parse(
  tag: String,
  url: String,
  host: String,
  path: List(String),
) -> Result(Embed, Nil) {
  case tag, host, path {
    "LinkCard", _, _ -> Ok(LinkCard(url))
    "GitHubRepository", "github.com", [owner, repo] ->
      Ok(GitHubRepository(url:, owner:, repo:))
    "Tweet", "x.com", [_, "status", id]
    | "Tweet", "twitter.com", [_, "status", id]
    -> Ok(Tweet(url:, id:))
    "SpeakerDeck", "speakerdeck.com", [_, _] -> Ok(SpeakerDeck(url))
    "Docswell", "www.docswell.com", ["s", _, _] -> Ok(Docswell(url))
    "NpmPackage", "www.npmjs.com", ["package", "@" <> _ as scope, name] ->
      Ok(NpmPackage(url:, name: scope <> "/" <> name))
    "NpmPackage", "www.npmjs.com", ["package", name] ->
      Ok(NpmPackage(url:, name:))
    _, _, _ -> Error(Nil)
  }
}

pub fn view(context: Context, embed: Embed) -> Promise(Element(msg)) {
  case embed {
    LinkCard(url:) ->
      render(link_card_api.fetch(context, url), url, link_card.view)
    GitHubRepository(url:, owner:, repo:) ->
      render(
        github_repository_api.fetch(context, owner, repo),
        url,
        github_repository.view,
      )
    Tweet(url:, id:) ->
      render(tweet_api.fetch(context, url, id), url, tweet.view)
    SpeakerDeck(url:) ->
      render(slide_api.speaker_deck(context, url), url, slide.view)
    Docswell(url:) -> render(slide_api.docswell(context, url), url, slide.view)
    NpmPackage(url:, name:) ->
      render(npm_package_api.fetch(context, url, name), url, npm_package.view)
  }
}

fn render(
  fetched: Promise(Result(a, Nil)),
  url: String,
  view: fn(a) -> Element(msg),
) -> Promise(Element(msg)) {
  use fetched <- promise.map(fetched)

  case fetched {
    Ok(data) -> view(data)
    Error(Nil) ->
      html.p([attribute.class("truncate")], [text_link.view(url, url)])
  }
}

fn host_and_path(url: String) -> Result(#(String, List(String)), Nil) {
  case uri.parse(url) {
    Ok(uri.Uri(scheme: Some(scheme), host: Some(host), path:, ..))
      if { scheme == "https" || scheme == "http" } && host != ""
    -> Ok(#(string.lowercase(host), uri.path_segments(path)))
    _ -> Error(Nil)
  }
}
