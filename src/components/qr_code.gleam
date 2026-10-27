import gleam/int
import gleam/list
import gleam/string
import glqr
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg

const quiet_zone = 4

pub fn view(text: String, label: String) -> Element(msg) {
  let generated =
    glqr.new(text)
    |> glqr.error_correction(glqr.M)
    |> glqr.generate

  case generated {
    Ok(qr) -> {
      let #(size, bits) = glqr.to_bits(qr)
      view_modules(list.sized_chunk(modules(bits, []), size), label)
    }
    Error(_) -> element.none()
  }
}

fn modules(bits: BitArray, acc: List(Bool)) -> List(Bool) {
  case bits {
    <<1:1, rest:bits>> -> modules(rest, [True, ..acc])
    <<0:1, rest:bits>> -> modules(rest, [False, ..acc])
    _ -> list.reverse(acc)
  }
}

fn view_modules(modules: List(List(Bool)), label: String) -> Element(msg) {
  let size = int.to_string(list.length(modules) + quiet_zone * 2)
  let path =
    modules
    |> list.index_map(fn(row, y) {
      list.index_map(row, fn(dark, x) {
        case dark {
          True ->
            "M"
            <> int.to_string(x + quiet_zone)
            <> " "
            <> int.to_string(y + quiet_zone)
            <> "h1v1h-1z"
          False -> ""
        }
      })
    })
    |> list.flatten
    |> string.concat

  html.svg(
    [
      attribute.attribute("viewBox", "0 0 " <> size <> " " <> size),
      attribute.attribute("shape-rendering", "crispEdges"),
      attribute.role("img"),
      attribute.aria_label(label),
      attribute.class("aspect-square w-full bg-bg"),
    ],
    [svg.path([attribute.attribute("d", path), attribute.class("fill-fg")])],
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
