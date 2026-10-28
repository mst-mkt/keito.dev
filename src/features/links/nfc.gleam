import components/button
import components/icons
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub const id = "nfc"

pub const label_id = "nfc-label"

pub const status_id = "nfc-status"

pub fn view(url: String) -> Element(msg) {
  element.fragment([
    button.new()
      |> button.class("grow basis-36")
      |> button.view(
        [
          attribute.type_("button"),
          attribute.id(id),
          attribute.data("url", url),
          attribute.hidden(True),
        ],
        [
          icons.contactless([attribute.aria_hidden(True)]),
          html.span([attribute.id(label_id)], [html.text("Write to NFC")]),
        ],
      ),
    html.span(
      [
        attribute.id(status_id),
        attribute.role("status"),
        attribute.class("sr-only"),
      ],
      [],
    ),
  ])
}
