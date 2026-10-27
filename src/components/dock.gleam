import components/button
import components/icons
import gleam/int
import gleam/list
import gleam/result
import lib/cn.{cn}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub type Item(msg) {
  Link(
    label: String,
    href: String,
    icon: fn(List(Attribute(msg))) -> Element(msg),
  )
  Panel(
    label: String,
    content: List(Element(msg)),
    icon: fn(List(Attribute(msg))) -> Element(msg),
  )
}

pub const id = "dock"

pub const controls_id = "dock-controls"

pub const close_id = "dock-close"

pub fn view(label: String, items: List(Item(msg))) -> Element(msg) {
  case items {
    [] -> element.none()
    _ -> view_dock(label, items)
  }
}

fn view_dock(label: String, items: List(Item(msg))) -> Element(msg) {
  let panels =
    list.index_map(items, fn(item, index) {
      case item {
        Link(..) -> Error(Nil)
        Panel(label:, content:, ..) -> Ok(#(panel_id(index), label, content))
      }
    })
    |> result.values
  let controls =
    html.ul(
      [
        attribute.id(controls_id),
        attribute.class(
          cn([
            "col-start-1 row-start-1 flex justify-center gap-0.5 transition-[opacity,translate] delay-150 duration-200",
            "group-data-open/dock:translate-y-2 group-data-open/dock:opacity-0 group-data-open/dock:delay-0",
          ]),
        ),
      ],
      list.index_map(items, fn(item, index) {
        html.li([attribute.class("flex")], [view_control(item, index)])
      }),
    )

  html.nav(
    [
      attribute.id(id),
      attribute.aria_label(label),
      attribute.class(
        cn([
          "group/dock @container pointer-events-none fixed inset-x-0 bottom-0 z-10 flex justify-center bg-linear-to-t from-bg px-4 pt-12 pb-4",
          "transition-[display,translate,opacity] transition-discrete duration-300 ease-out starting:translate-y-2 starting:opacity-0",
          "xl:hidden xl:translate-y-2 xl:opacity-0",
        ]),
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            cn([
              "pointer-events-auto flex max-w-md flex-col rounded-xl bg-bg inset-ring inset-ring-border group-data-open/dock:grow",
              "transition-[flex-grow] delay-100 duration-300 ease-out group-data-open/dock:delay-0",
            ]),
          ),
        ],
        [
          case panels {
            [] -> element.none()
            _ ->
              html.div(
                [
                  attribute.class(
                    "grid w-0 min-w-full grid-rows-[0fr] content-end overflow-clip transition-[grid-template-rows] delay-100 duration-300 ease-out group-data-open/dock:grid-rows-[1fr] group-data-open/dock:delay-0",
                  ),
                ],
                [
                  html.div(
                    [
                      attribute.class(
                        "grid min-h-0 min-w-0 content-end justify-center",
                      ),
                    ],
                    list.map(panels, view_panel),
                  ),
                ],
              )
          },
          html.div([attribute.class("grid p-1")], [
            controls,
            case panels {
              [] -> element.none()
              _ -> view_close()
            },
          ]),
        ],
      ),
    ],
  )
}

fn view_close() -> Element(msg) {
  html.div(
    [
      attribute.class(
        cn([
          "invisible col-start-1 row-start-1 grid opacity-0 transition-[opacity,visibility] duration-200",
          "group-data-open/dock:visible group-data-open/dock:opacity-100 group-data-open/dock:delay-200",
        ]),
      ),
    ],
    [
      button.new()
      |> button.variant(button.Ghost)
      |> button.class("w-full [&_svg]:size-5")
      |> button.view(
        [
          attribute.type_("button"),
          attribute.id(close_id),
          attribute.aria_label("Close"),
        ],
        [icons.nav_arrow_down([attribute.aria_hidden(True)])],
      ),
    ],
  )
}

fn view_control(item: Item(msg), index: Int) -> Element(msg) {
  let control =
    button.new()
    |> button.variant(button.Ghost)
    |> button.size(button.Icon)
    |> button.class("size-10 [&_svg]:size-5")
  let icon = item.icon([attribute.aria_hidden(True)])

  case item {
    Link(label:, href:, ..) ->
      control |> button.link(href, [attribute.aria_label(label)], [icon])
    Panel(label:, ..) ->
      control
      |> button.view(
        [
          attribute.type_("button"),
          attribute.aria_label(label),
          attribute.aria_expanded(False),
          attribute.aria_controls(panel_id(index)),
        ],
        [icon],
      )
  }
}

fn view_panel(panel: #(String, String, List(Element(msg)))) -> Element(msg) {
  let #(id, label, content) = panel

  html.dialog(
    [
      attribute.id(id),
      attribute.aria_label(label),
      attribute.tabindex(-1),
      attribute.class(
        "group static col-start-1 row-start-1 w-md max-w-[100cqw] bg-transparent text-inherit transition-[display] transition-discrete duration-400 outline-none",
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            cn([
              "grid max-h-[60dvh] gap-y-3 overflow-y-auto overscroll-contain px-5 pt-5 pb-3 text-sm",
              "opacity-0 blur-sm transition-[opacity,filter] duration-200",
              "group-open:opacity-100 group-open:blur-none group-open:delay-200",
              "starting:group-open:opacity-0 starting:group-open:blur-sm",
            ]),
          ),
        ],
        content,
      ),
    ],
  )
}

fn panel_id(index: Int) -> String {
  "dock-panel-" <> int.to_string(index)
}
