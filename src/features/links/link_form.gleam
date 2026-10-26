import bindings/env.{type Env}
import components/button
import components/text_input
import features/links/link.{type Errors, type Link, Errors, Link}
import features/links/store
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn draft(fields: List(#(String, String))) -> Link {
  let field = fn(key) { list.key_find(fields, key) |> result.unwrap("") }

  Link(id: field("id"), name: field("name"), url: field("url"))
}

pub fn submit(
  env: Env,
  draft: Link,
  replacing from: Option(String),
) -> Promise(Result(Link, Errors)) {
  case link.parse(draft) {
    Error(errors) -> promise.resolve(Error(errors))
    Ok(parsed) -> {
      use saved <- promise.map(store.save(env, parsed, replacing: from))

      result.replace(saved, parsed)
      |> result.replace_error(link.taken(parsed.id))
    }
  }
}

pub fn view(draft: Link, errors: Errors, submit_label: String) -> Element(Nil) {
  let focus = case errors {
    Errors(id: Some(_), ..) -> "id"
    Errors(name: Some(_), ..) -> "name"
    Errors(url: Some(_), ..) -> "url"
    _ -> ""
  }

  html.form([attribute.method("post"), attribute.class("grid gap-y-6")], [
    text_input.view(
      name: "id",
      label: "ID",
      value: draft.id,
      required: True,
      error: errors.id,
      attributes: [
        attribute.autocomplete("off"),
        attribute.autocapitalize("none"),
        attribute.spellcheck(False),
        attribute.autofocus(focus == "id"),
      ],
    ),
    text_input.view(
      name: "name",
      label: "Name",
      value: draft.name,
      required: False,
      error: errors.name,
      attributes: [
        attribute.autocomplete("off"),
        attribute.autofocus(focus == "name"),
      ],
    ),
    text_input.view(
      name: "url",
      label: "URL",
      value: draft.url,
      required: True,
      error: errors.url,
      attributes: [
        attribute.type_("url"),
        attribute.inputmode("url"),
        attribute.placeholder("https://"),
        attribute.autocomplete("off"),
        attribute.autofocus(focus == "url"),
      ],
    ),
    button.new()
      |> button.variant(button.Primary)
      |> button.view([attribute.type_("submit")], [html.text(submit_label)]),
  ])
}
