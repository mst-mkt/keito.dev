import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(text: String, href: String) -> Element(a) {
  html.a(
    [
      attribute.href(href),
      attribute.class(
        "rounded-xs underline decoration-border decoration-1 underline-offset-4 outline-offset-2 transition-colors hover:decoration-fg focus-visible:decoration-fg focus-visible:outline-2 focus-visible:outline-fg",
      ),
    ],
    [html.text(text)],
  )
}
