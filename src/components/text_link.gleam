import components/icons
import lib/story.{type Story}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub fn view(text: String, href: String) -> Element(a) {
  link(href, [html.text(text)])
}

pub fn with_icon(
  text: String,
  href: String,
  icon: fn(List(Attribute(a))) -> Element(a),
) -> Element(a) {
  link(href, [
    icon([
      attribute.aria_hidden(True),
      attribute.class(
        "mr-1 ml-0.5 inline size-[1.25em] align-[calc((1cap-1.25em)/2)]",
      ),
    ]),
    html.text(text),
  ])
}

fn link(href: String, children: List(Element(a))) -> Element(a) {
  html.a(
    [
      attribute.href(href),
      attribute.class(
        "rounded-xs underline decoration-border decoration-1 underline-offset-4 outline-offset-2 transition-colors hover:decoration-fg focus-visible:decoration-fg focus-visible:outline-2 focus-visible:outline-fg",
      ),
    ],
    children,
  )
}

@internal
pub fn stories() -> List(Story) {
  [
    story.new("default", {
      use text <- story.text("text", "keito.dev")

      story.render(
        html.p([], [html.text("Visit "), view(text, "#"), html.text(".")]),
      )
    }),
    story.new("icon", {
      use text <- story.text("text", "Hatena")

      story.render(
        html.p([], [
          html.text("Working part-time at "),
          with_icon(text, "#", icons.hatena),
          html.text("."),
        ]),
      )
    }),
  ]
}
