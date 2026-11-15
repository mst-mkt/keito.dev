import features/blog/markdown/inline
import gleam/list
import gleam/string
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html
import mork/document.{
  type Alignment, type Cell, type Document, type Inline, type THead, Center,
  Left, Right, Text,
}

pub fn view(
  document: Document,
  header: List(THead),
  rows: List(List(Cell)),
) -> Element(msg) {
  let aligns = list.map(header, fn(head) { head.align })
  let content = fn(inlines) { inline.view(document, trim(inlines)) }
  let head =
    list.map(header, fn(head) {
      html.th(align_attributes(head.align), content(head.inlines))
    })
  let body =
    list.map(rows, fn(row) {
      html.tr(
        [],
        list.map2(row, aligns, fn(cell, align) {
          html.td(align_attributes(align), content(cell.inlines))
        }),
      )
    })

  html.div([attribute.class("overflow-x-auto"), attribute.tabindex(0)], [
    html.table([], [html.thead([], [html.tr([], head)]), html.tbody([], body)]),
  ])
}

fn align_attributes(align: Alignment) -> List(Attribute(msg)) {
  case align {
    Left -> []
    Center -> [attribute.style("text-align", "center")]
    Right -> [attribute.style("text-align", "right")]
  }
}

fn trim(inlines: List(Inline)) -> List(Inline) {
  inlines
  |> trim_first(string.trim_start)
  |> list.reverse
  |> trim_first(string.trim_end)
  |> list.reverse
}

fn trim_first(
  inlines: List(Inline),
  trim: fn(String) -> String,
) -> List(Inline) {
  case inlines {
    [Text(text), ..rest] -> [Text(trim(text)), ..rest]
    inlines -> inlines
  }
}
