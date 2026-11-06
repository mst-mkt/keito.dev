import gleam/float
import gleam/javascript/array
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import lib/story
import plinth/browser/document
import plinth/browser/element.{type Element}
import plinth/browser/web_storage.{type Storage}

const scroll_key = "story-nav-scroll"

const open_key = "story-nav-open"

pub fn enhance() -> Nil {
  let _ = {
    use nav <- result.try(document.get_element_by_id(story.nav_id))
    use storage <- result.map(
      web_storage.session() |> result.replace_error(Nil),
    )

    restore(nav, storage)
    document.add_event_listener("visibilitychange", fn(_) { save(nav, storage) })
  }
  Nil
}

fn restore(nav: Element, storage: Storage) -> Nil {
  let open = case web_storage.get_item(storage, open_key) {
    Ok(Some(value)) -> string.split(value, "\n")
    _ -> []
  }
  let top = case web_storage.get_item(storage, scroll_key) {
    Ok(Some(value)) -> float.parse(value)
    _ -> Error(Nil)
  }

  module_details(nav)
  |> list.filter(fn(details) {
    case element.dataset_get(details, "module") {
      Ok(module) -> list.contains(open, module)
      Error(_) -> False
    }
  })
  |> list.each(element.set_attribute(_, "open", ""))

  case top, element.query_selector(nav, "[aria-current=page]") {
    Ok(top), _ -> element.set_scroll_top(nav, top)
    Error(_), Ok(current) -> element.scroll_into_view(current)
    Error(_), Error(_) -> Nil
  }
}

fn save(nav: Element, storage: Storage) -> Nil {
  let open =
    module_details(nav)
    |> list.filter(element.matches(_, "[open]"))
    |> list.filter_map(element.dataset_get(_, "module"))
    |> string.join("\n")

  let _ = web_storage.set_item(storage, open_key, open)
  let _ =
    web_storage.set_item(
      storage,
      scroll_key,
      float.to_string(element.scroll_top(nav)),
    )
  Nil
}

fn module_details(nav: Element) -> List(Element) {
  element.query_selector_all(nav, "details") |> array.to_list
}
