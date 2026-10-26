import lib/cn.{cn}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub opaque type Button {
  Button(variant: Variant, size: Size, class: String)
}

pub type Variant {
  Primary
  Secondary
  Ghost
  Danger
}

pub type Size {
  Default
  Icon
}

pub fn new() -> Button {
  Button(variant: Secondary, size: Default, class: "")
}

pub fn variant(button: Button, variant: Variant) -> Button {
  Button(..button, variant:)
}

pub fn size(button: Button, size: Size) -> Button {
  Button(..button, size:)
}

pub fn class(button: Button, class: String) -> Button {
  Button(..button, class:)
}

pub fn view(
  button: Button,
  attributes: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.button([classes(button), ..attributes], children)
}

pub fn link(
  button: Button,
  href: String,
  attributes: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.a([attribute.href(href), classes(button), ..attributes], children)
}

fn classes(button: Button) -> Attribute(msg) {
  let variant = case button.variant {
    Primary -> "bg-fg text-bg hover:bg-fg/85"
    Secondary -> "bg-control hover:bg-control-hover"
    Ghost -> "text-subtle hover:bg-control-hover hover:text-fg"
    Danger -> "bg-danger/10 text-danger hover:bg-danger/15"
  }
  let size = case button.size {
    Default -> "h-10 px-4"
    Icon -> "size-9"
  }

  attribute.class(
    cn([
      "inline-flex w-fit cursor-pointer items-center justify-center gap-x-2 rounded-lg",
      "text-sm font-medium whitespace-nowrap [&_svg]:size-4 [&_svg]:shrink-0",
      "outline-0 outline-fg/25 outline-solid focus-visible:outline-3",
      "transition-[color,background-color,outline-width] duration-100 ease-out",
      "disabled:pointer-events-none disabled:opacity-50",
      variant,
      size,
      button.class,
    ]),
  )
}
