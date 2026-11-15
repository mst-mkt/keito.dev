import components/text_link
import features/blog/embed/api/github_permalink as github_permalink_api
import features/blog/embed/api/github_repository as github_repository_api
import features/blog/embed/api/link_card as link_card_api
import features/blog/embed/api/npm_package as npm_package_api
import features/blog/embed/api/slide as slide_api
import features/blog/embed/api/tweet as tweet_api
import features/blog/embed/components/github_permalink.{
  type Lines, Range, WholeFile,
}
import features/blog/embed/components/github_repository
import features/blog/embed/components/link_card
import features/blog/embed/components/npm_package
import features/blog/embed/components/slide
import features/blog/embed/components/tweet
import gleam/bool
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}
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
  GitHubPermalink(
    url: String,
    owner: String,
    repo: String,
    ref: String,
    path: String,
    lines: Lines,
  )
  Tweet(url: String, id: String)
  SpeakerDeck(url: String)
  Docswell(url: String)
  NpmPackage(url: String, name: String)
}

const tags = [
  "LinkCard", "GitHubRepository", "GitHubPermalink", "Tweet", "SpeakerDeck",
  "Docswell", "NpmPackage",
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
    use #(host, path, fragment) <- result.try(split(url))

    parse(tag, url, host, path, fragment)
  }
  |> result.replace_error(element <> " does not support " <> url <> ".")
}

fn parse(
  tag: String,
  url: String,
  host: String,
  path: List(String),
  fragment: Option(String),
) -> Result(Embed, Nil) {
  case tag, host, path {
    "LinkCard", _, _ -> Ok(LinkCard(url))
    "GitHubRepository", "github.com", [owner, repo] ->
      Ok(GitHubRepository(url:, owner:, repo:))
    "GitHubPermalink", "github.com", [owner, repo, "blob", ref, first, ..rest]
    -> {
      let path = string.join([first, ..rest], "/")
      use lines <- result.map(lines(fragment))

      GitHubPermalink(url:, owner:, repo:, ref:, path:, lines:)
    }
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
  use viewed <- promise.map(try_view(context, embed))

  case viewed {
    Ok(element) | Error(element) -> element
  }
}

pub fn try_view(
  context: Context,
  embed: Embed,
) -> Promise(Result(Element(msg), Element(msg))) {
  case embed {
    LinkCard(url:) ->
      render(link_card_api.fetch(context, url), url, link_card.view)
    GitHubRepository(url:, owner:, repo:) ->
      render(
        github_repository_api.fetch(context, owner, repo),
        url,
        github_repository.view,
      )
    GitHubPermalink(url:, owner:, repo:, ref:, path:, lines:) ->
      render(
        github_permalink_api.fetch(context, url, owner, repo, ref, path, lines),
        url,
        github_permalink.view,
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
) -> Promise(Result(Element(msg), Element(msg))) {
  use fetched <- promise.map(fetched)

  case fetched {
    Ok(data) -> Ok(view(data))
    Error(Nil) ->
      Error(html.p([attribute.class("truncate")], [text_link.view(url, url)]))
  }
}

fn split(url: String) -> Result(#(String, List(String), Option(String)), Nil) {
  case uri.parse(url) {
    Ok(uri.Uri(scheme: Some(scheme), host: Some(host), path:, fragment:, ..))
      if { scheme == "https" || scheme == "http" } && host != ""
    -> Ok(#(string.lowercase(host), uri.path_segments(path), fragment))
    _ -> Error(Nil)
  }
}

fn lines(fragment: Option(String)) -> Result(Lines, Nil) {
  case fragment {
    None -> Ok(WholeFile)
    Some("L" <> range) ->
      case string.split(range, "-L") |> list.try_map(int.parse) {
        Ok([line]) if line >= 1 -> Ok(Range(line, line))
        Ok([start, end]) if start >= 1 && start <= end -> Ok(Range(start, end))
        _ -> Error(Nil)
      }
    Some(_) -> Error(Nil)
  }
}
