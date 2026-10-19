import layouts/base
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(Nil) {
  base.document("Not Found", [html.h1([], [html.text("Not Found")])], [])
}
