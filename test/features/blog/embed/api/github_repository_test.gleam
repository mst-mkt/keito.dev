import features/blog/embed/api/github_repository as api
import features/blog/embed/components/github_repository.{Language, Repository}
import gleam/json
import gleam/option.{None, Some}

fn body(language: json.Json) -> String {
  json.object([
    #("url", json.string("https://github.com/mst-mkt/nuten")),
    #("name", json.string("nuten")),
    #("owner", json.object([#("login", json.string("mst-mkt"))])),
    #(
      "description",
      json.string("A formatter for Nushell. Robust, fast, and lightweight."),
    ),
    #("stargazerCount", json.int(1)),
    #("primaryLanguage", language),
  ])
  |> json.to_string
}

pub fn decoder_test() {
  let body =
    body(
      json.object([
        #("name", json.string("Rust")),
        #("color", json.string("#dea584")),
      ]),
    )

  let result = json.parse(body, api.decoder())

  assert result
    == Ok(Repository(
      url: "https://github.com/mst-mkt/nuten",
      owner: "mst-mkt",
      name: "nuten",
      description: Some(
        "A formatter for Nushell. Robust, fast, and lightweight.",
      ),
      stars: 1,
      language: Some(Language(name: "Rust", color: "#dea584")),
    ))
}

pub fn decoder_without_language_test() {
  let body = body(json.null())

  let assert Ok(Repository(language:, ..)) = json.parse(body, api.decoder())

  assert language == None
}
