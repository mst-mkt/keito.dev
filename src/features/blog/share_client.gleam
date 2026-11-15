import features/blog/share
import gleam/bool
import gleam/javascript/promise
import gleam/result
import lib/web_share
import plinth/browser/clipboard
import plinth/browser/document
import plinth/browser/element.{type Element}

const reset_after_ms = 2000

pub fn enhance() -> Nil {
  let _ = enhance_copy()
  let _ = enhance_sheet()
  Nil
}

fn enhance_copy() -> Result(Nil, Nil) {
  use button <- result.try(document.get_element_by_id(share.copy_id))
  use status <- result.try(document.get_element_by_id(share.status_id))
  use url <- result.map(element.dataset_get(button, "url"))

  element.remove_attribute(button, "hidden")
  let _ =
    element.add_event_listener(button, "click", fn(_) {
      copy(button, status, url)
    })
  Nil
}

fn enhance_sheet() -> Result(Nil, Nil) {
  use <- bool.guard(when: !web_share.is_supported(), return: Error(Nil))
  use button <- result.try(document.get_element_by_id(share.sheet_id))
  use url <- result.try(element.dataset_get(button, "url"))
  use title <- result.map(element.dataset_get(button, "title"))

  element.remove_attribute(button, "hidden")
  let _ =
    element.add_event_listener(button, "click", fn(_) {
      let _ = web_share.share(title:, url:)
      Nil
    })
  Nil
}

fn copy(button: Element, status: Element, url: String) -> Nil {
  let copied = result.is_ok(element.get_attribute(button, "data-copied"))
  use <- bool.guard(when: copied, return: Nil)

  let _ = {
    use result <- promise.await(clipboard.write_text(url))

    case result {
      Ok(Nil) -> {
        element.set_attribute(button, "data-copied", "")
        element.set_text_content(status, "Copied")
      }
      Error(_) -> element.set_text_content(status, "Failed to copy")
    }

    use _ <- promise.map(promise.wait(reset_after_ms))
    element.remove_attribute(button, "data-copied")
    element.set_text_content(status, "")
  }
  Nil
}
