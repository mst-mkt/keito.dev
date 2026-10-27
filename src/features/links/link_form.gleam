import components/button
import components/text_input
import features/links/link.{type Draft, type Errors, Errors}
import gleam/option.{Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(
  draft: Draft,
  errors: Errors,
  submit_label: String,
) -> Element(Nil) {
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
