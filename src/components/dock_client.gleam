import components/dock
import gleam/javascript/array
import gleam/list
import plinth/browser/document
import plinth/browser/element.{type Element}
import plinth/browser/event.{type Event, type KeyboardEvent, type UIEvent}

pub fn enhance() -> Nil {
  case
    document.get_element_by_id(dock.id),
    document.get_element_by_id(dock.controls_id),
    document.get_element_by_id(dock.close_id)
  {
    Ok(nav), Ok(controls), Ok(close_button) -> {
      element.query_selector_all(controls, "button[aria-controls]")
      |> array.to_list
      |> list.each(fn(trigger) {
        let _ =
          element.add_event_listener(trigger, "click", fn(_) {
            open(nav, controls, trigger)
          })
        Nil
      })
      let _ =
        element.add_event_listener(close_button, "click", fn(_) {
          close(nav, controls, restore_focus: True)
        })

      document.add_event_listener(
        "keydown",
        fn(event: Event(UIEvent(KeyboardEvent))) {
          case event.key(event), event.is_composing(event) {
            "Escape", False ->
              close(
                nav,
                controls,
                restore_focus: element.matches(nav, ":focus-within"),
              )
            _, _ -> Nil
          }
        },
      )
      document.add_event_listener("pointerdown", fn(event: Event(Nil)) {
        case element.cast(event.target(event)) {
          Ok(target) ->
            case element.contains(nav, target) {
              True -> Nil
              False -> close(nav, controls, restore_focus: False)
            }
          Error(_) -> Nil
        }
      })
    }
    _, _, _ -> Nil
  }
}

fn open(nav: Element, controls: Element, trigger: Element) -> Nil {
  case panel(trigger) {
    Ok(panel) -> {
      element.set_attribute(nav, "data-open", "")
      element.set_attribute(panel, "open", "")
      element.set_attribute(trigger, "aria-expanded", "true")
      element.set_attribute(controls, "inert", "")
      element.focus(panel)
    }
    Error(_) -> Nil
  }
}

fn close(
  nav: Element,
  controls: Element,
  restore_focus restore_focus: Bool,
) -> Nil {
  case element.query_selector(controls, "[aria-expanded=true]") {
    Ok(trigger) -> {
      element.remove_attribute(nav, "data-open")
      element.set_attribute(trigger, "aria-expanded", "false")
      case panel(trigger) {
        Ok(panel) -> element.remove_attribute(panel, "open")
        Error(_) -> Nil
      }
      element.remove_attribute(controls, "inert")
      case restore_focus {
        True -> element.focus(trigger)
        False -> Nil
      }
    }
    Error(_) -> Nil
  }
}

fn panel(trigger: Element) -> Result(Element, Nil) {
  case element.get_attribute(trigger, "aria-controls") {
    Ok(id) -> document.get_element_by_id(id)
    Error(_) -> Error(Nil)
  }
}
