import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn property(name: String, content: String) -> Element(msg) {
  html.meta([attribute.attribute("property", name), attribute.content(content)])
}
