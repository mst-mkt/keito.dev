import gleam/list
import lib/cn.{cn}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub type Item(msg) {
  Item(
    text: String,
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
            "flex w-fit items-center gap-x-2 rounded-sm text-sm",
            "text-subtle transition-colors hover:text-fg focus-visible:text-fg",
            "outline-offset-4 focus-visible:outline-2 focus-visible:outline-fg",
          ]),
        ),
      ],
      [
        item.icon([attribute.aria_hidden(True), attribute.class("size-4")]),
        html.text(item.text),
      ],
    ),
  ])
}
