import gleam/option.{type Option, None, Some}
import lib/cn.{cn}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub fn id(name: String) -> String {
  "field-" <> name
}

pub fn error_id(name: String) -> String {
  id(name) <> "-error"
}

pub fn view(
  name name: String,
  label label: String,
  value value: String,
  required required: Bool,
  error error: Option(String),
  attributes attributes: List(Attribute(msg)),
) -> Element(msg) {
  html.div([attribute.class("grid gap-y-2")], [
    html.label(
      [
        attribute.for(id(name)),
        attribute.class("flex items-baseline gap-x-2 text-sm text-muted"),
      ],
      [
        html.text(label),
        case required {
          True -> element.none()
          False ->
            html.span([attribute.class("text-xs text-subtle")], [
              html.text("Optional"),
            ])
        },
      ],
    ),
    html.input([
      attribute.id(id(name)),
      attribute.name(name),
      attribute.value(value),
      attribute.required(required),
      attribute.aria_describedby(error_id(name)),
      attribute.aria_invalid(case error {
        Some(_) -> "true"
        None -> "false"
      }),
      attribute.class(
        cn([
          "h-10 w-full min-w-0 rounded-lg px-3 text-base placeholder:text-subtle",
          "bg-control hover:bg-control-hover",
          "outline-0 outline-fg/25 outline-solid focus-visible:outline-3",
          "transition-[color,background-color,outline-width] duration-100 ease-out",
          "aria-invalid:bg-danger/8 aria-invalid:outline-danger/35",
        ]),
      ),
      ..attributes
    ]),
    html.p(
      [
        attribute.id(error_id(name)),
        attribute.class("text-sm text-danger empty:hidden"),
      ],
      case error {
        Some(text) -> [html.text(text)]
        None -> []
      },
    ),
  ])
}
