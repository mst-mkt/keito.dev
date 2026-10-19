import layouts/base
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(Nil) {
  base.document("Home", [html.h1([], [html.text("keito.dev")])], [])
}
