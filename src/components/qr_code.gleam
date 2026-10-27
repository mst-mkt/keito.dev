import gleam/int
import gleam/list
import gleam/string
import lib/qr
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg

const quiet_zone = 4

pub fn view(text: String, label: String) -> Element(msg) {
  case qr.modules(text) {
    Ok(modules) -> view_modules(modules, label)
    Error(_) -> element.none()
  }
}

fn view_modules(modules: List(List(Bool)), label: String) -> Element(msg) {
  let origin = int.to_string(-quiet_zone)
  let size = int.to_string(list.length(modules) + quiet_zone * 2)
  let view_box = [origin, origin, size, size]

  html.svg(
    [
      attribute.attribute("viewBox", string.join(view_box, " ")),
      attribute.attribute("shape-rendering", "crispEdges"),
      attribute.role("img"),
      attribute.aria_label(label),
      attribute.class("aspect-square w-full bg-bg"),
    ],
    [
      svg.path([
        attribute.attribute("d", qr.path(modules)),
        attribute.class("fill-fg"),
      ]),
    ],
  )
}

@internal
pub fn stories() -> List(Story) {
  [
    story.new("default", {
      use text <- story.text("text", "https://keito.dev/l/example")

      story.render(
        html.div([attribute.class("max-w-xs")], [
          view(text, "QR code for " <> text),
        ]),
      )
    }),
  ]
}
