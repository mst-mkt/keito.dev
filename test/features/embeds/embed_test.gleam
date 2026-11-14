import features/embeds/embed.{
  Docswell, GitHubRepository, LinkCard, NpmPackage, SpeakerDeck, Tweet,
}

pub fn from_tag_link_card_test() {
  let url = "https://nuten.keito.dev/"

  let result = embed.from_tag("LinkCard", [#("url", url)])

  assert result == Ok(LinkCard(url))
}

pub fn from_tag_non_http_url_test() {
  let url = "ftp://keito.dev/"

  let result = embed.from_tag("LinkCard", [#("url", url)])

  assert result == Error("<LinkCard> does not support ftp://keito.dev/.")
}

pub fn from_tag_github_repository_test() {
  let url = "https://github.com/mst-mkt/nuten"

  let result = embed.from_tag("GitHubRepository", [#("url", url)])

  assert result == Ok(GitHubRepository(url:, owner: "mst-mkt", repo: "nuten"))
}

pub fn from_tag_github_repository_without_repo_test() {
  let url = "https://github.com/mst-mkt"

  let result = embed.from_tag("GitHubRepository", [#("url", url)])

  assert result
    == Error("<GitHubRepository> does not support https://github.com/mst-mkt.")
}

pub fn from_tag_tweet_test() {
  let url = "https://x.com/mst_mkt_/status/1"

  let result = embed.from_tag("Tweet", [#("url", url)])

  assert result == Ok(Tweet(url:, id: "1"))
}

pub fn from_tag_tweet_on_twitter_test() {
  let url = "https://twitter.com/mst_mkt_/status/1"

  let result = embed.from_tag("Tweet", [#("url", url)])

  assert result == Ok(Tweet(url:, id: "1"))
}

pub fn from_tag_speaker_deck_test() {
  let url = "https://speakerdeck.com/speakerdeck/introduction-to-speakerdeck"

  let result = embed.from_tag("SpeakerDeck", [#("url", url)])

  assert result == Ok(SpeakerDeck(url))
}

pub fn from_tag_docswell_test() {
  let url = "https://www.docswell.com/s/gaspanik/5VJNN3-2026-10-21-154052"

  let result = embed.from_tag("Docswell", [#("url", url)])

  assert result == Ok(Docswell(url))
}

pub fn from_tag_npm_package_test() {
  let url = "https://www.npmjs.com/package/vite"

  let result = embed.from_tag("NpmPackage", [#("url", url)])

  assert result == Ok(NpmPackage(url:, name: "vite"))
}

pub fn from_tag_npm_package_scoped_test() {
  let url = "https://www.npmjs.com/package/@mst-mkt/mixi2-application-sdk-ts"

  let result = embed.from_tag("NpmPackage", [#("url", url)])

  assert result
    == Ok(NpmPackage(url:, name: "@mst-mkt/mixi2-application-sdk-ts"))
}

pub fn from_tag_without_url_test() {
  let result = embed.from_tag("Tweet", [])

  assert result == Error("<Tweet> requires a url attribute.")
}

pub fn from_tag_unknown_tag_test() {
  let result = embed.from_tag("Rabbit", [#("url", "https://example.com")])

  assert result == Error("<Rabbit> is not an embed.")
}

pub fn from_tag_uppercase_host_test() {
  let url = "https://GitHub.com/mst-mkt/nuten"

  let result = embed.from_tag("GitHubRepository", [#("url", url)])

  assert result == Ok(GitHubRepository(url:, owner: "mst-mkt", repo: "nuten"))
}
