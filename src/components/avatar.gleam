import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lib/cn.{cn}
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg

const image = "/avatar.png"

const yarn = [
  "...rdrd...",
  "..drdrdr..",
  ".mdrdrrdr.",
  ".mdrdrdrd.",
  ".mdrrdrdr.",
  ".mdrdrdrd.",
  "..mdrdrd..",
  ".m.mkmk...",
  ".m......r.",
  "..rrrrrr..",
]

const shades = [
  #("r", "fill-fg/35 animate-pulse"),
  #("m", "fill-fg/45 animate-pulse"),
  #("d", "fill-fg/60 animate-pulse"),
  #("k", "fill-fg/70 animate-pulse"),
]

type Cell {
  Cell(x: Int, y: Int, shade: String, delay: Int)
}

pub fn view() -> Element(msg) {
  let cells =
    yarn
    |> list.index_map(fn(row, y) {
      row
      |> string.to_graphemes
      |> list.index_map(fn(char, x) {
        let shade = list.key_find(shades, char)
        Cell(
          x: x * 10,
          y: y * 10,
          shade: result.unwrap(shade, "fill-fg/10"),
          delay: delay(x, y, result.is_ok(shade)),
        )
      })
    })
    |> list.flatten

  html.svg(
    [
      attribute.attribute("viewBox", "0 0 100 100"),
      attribute.class("size-24 rounded-xl"),
      attribute.aria_hidden(True),
    ],
    [
      svg.defs([], [
        svg.style(
          [],
          "@keyframes avatar-reveal { from { visibility: hidden; scale: 0.8; } }",
        ),
        svg.clip_path(
          [attribute.id("avatar-reveal")],
          list.map(cells, view_reveal),
        ),
      ]),
      svg.g([], list.map(cells, view_dot)),
      svg.image([
        attribute.href(image),
        attribute.width(100),
        attribute.height(100),
        attribute.attribute("clip-path", "url(#avatar-reveal)"),
      ]),
    ],
  )
}

fn view_dot(cell: Cell) -> Element(msg) {
  svg.rect([
    attribute.attribute("x", int.to_string(cell.x + 1)),
    attribute.attribute("y", int.to_string(cell.y + 1)),
    attribute.width(8),
    attribute.height(8),
    attribute.attribute("rx", "1"),
    attribute.class(cn([cell.shade, "motion-reduce:animate-none"])),
  ])
}

fn view_reveal(cell: Cell) -> Element(msg) {
  svg.rect([
    attribute.attribute("x", int.to_string(cell.x)),
    attribute.attribute("y", int.to_string(cell.y)),
    attribute.width(10),
    attribute.height(10),
    attribute.attribute("rx", "1.25"),
    attribute.class(
      cn([
        "scale-120",
        "animate-[avatar-reveal_500ms_ease-out_both] motion-reduce:animate-none",
      ]),
    ),
    attribute.style(
      "transform-origin",
      int.to_string(cell.x + 5) <> "px " <> int.to_string(cell.y + 5) <> "px",
    ),
    attribute.style("animation-delay", int.to_string(cell.delay) <> "ms"),
  ])
}

fn delay(x: Int, y: Int, filled: Bool) -> Int {
  let dx = int.to_float(x) -. 4.5
  let dy = int.to_float(y) -. 4.5
  let assert Ok(distance) = float.square_root(dx *. dx +. dy *. dy)
  let checker = { x + y } % 2 * 60
  let outside = case filled {
    True -> 0
    False -> 100
  }

  1000 + float.round(distance *. 70.0) + checker + outside
}

@internal
pub fn stories() -> List(Story) {
  [story.new("default", story.render(view()))]
}
