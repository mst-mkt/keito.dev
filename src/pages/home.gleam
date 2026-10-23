import layouts/base
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(Nil) {
  base.document(
    "Home",
    left: [],
    content: [
      html.h1([attribute.class("text-2xl font-bold")], [html.text("keito.dev")]),
    ],
    right: [],
    scripts: [],
  )
}
