import components/icons
import gleam/list
import lib/cn.{cn}
import lib/story.{type Story}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub type Item(msg) {
  Item(
    label: String,
    href: String,
    icon: fn(List(Attribute(msg))) -> Element(msg),
  )
}

pub fn view(label: String, items: List(Item(msg))) -> Element(msg) {
  html.nav([attribute.aria_label(label)], [
    html.ul([attribute.class("grid gap-y-2")], list.map(items, view_item)),
  ])
}

fn view_item(item: Item(msg)) -> Element(msg) {
  html.li([], [
    html.a(
      [
        attribute.href(item.href),
        attribute.class(
          cn([
            "flex w-fit items-baseline gap-x-2 rounded-sm text-sm",
            "text-subtle transition-colors hover:text-fg focus-visible:text-fg",
            "outline-offset-4 focus-visible:outline-2 focus-visible:outline-fg",
          ]),
        ),
      ],
      [
        item.icon([
          attribute.aria_hidden(True),
          attribute.class("size-4 cap-center"),
        ]),
        html.text(item.label),
      ],
    ),
  ])
}

@internal
pub fn stories() -> List(Story) {
  [
    story.new("default", {
      use label <- story.text("label", "Navigation")

      story.render(
        view(label, [
          Item("Back to top", "#", icons.fast_arrow_left),
          Item("All links", "#", icons.nav_arrow_left),
        ]),
      )
    }),
  ]
}
