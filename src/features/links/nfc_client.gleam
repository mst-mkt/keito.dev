import features/links/nfc
import gleam/dynamic/decode
import gleam/javascript/promise
import gleam/result
import lib/ndef.{type Reader}
import plinth/browser/document
import plinth/browser/element.{type Element}

const reset_after_ms = 3000

pub fn enhance() -> Nil {
  let _ = {
    use trigger <- result.try(document.get_element_by_id(nfc.id))
    use label <- result.try(document.get_element_by_id(nfc.label_id))
    use status <- result.try(document.get_element_by_id(nfc.status_id))
    use url <- result.try(element.dataset_get(trigger, "url"))
    use reader <- result.map(ndef.reader())
    let feedback =
      Feedback(label:, status:, initial: element.text_content(label))

    element.remove_attribute(trigger, "hidden")
    element.add_event_listener(trigger, "click", fn(_) {
      write(reader, url, feedback)
    })
  }
  Nil
}

type Feedback {
  Feedback(label: Element, status: Element, initial: String)
}

fn write(reader: Reader, url: String, feedback: Feedback) -> Nil {
  announce(feedback, "Tap a tag")

  let _ =
    ndef.write_url(reader, url)
    |> promise.map(Ok)
    |> promise.rescue(fn(error) {
      decode.run(error, decode.at(["name"], decode.string))
      |> result.unwrap("")
      |> Error
    })
    |> promise.map(fn(result) {
      case result {
        Ok(Nil) -> show(feedback, "Written")
        Error("AbortError") -> Nil
        Error("NotAllowedError") -> show(feedback, "Not allowed")
        Error("NotSupportedError") -> show(feedback, "Not supported")
        Error(_) -> show(feedback, "Failed")
      }
    })
  Nil
}

fn show(feedback: Feedback, text: String) -> Nil {
  announce(feedback, text)

  let _ = {
    use _ <- promise.map(promise.wait(reset_after_ms))
    case element.text_content(feedback.label) == text {
      True -> element.set_text_content(feedback.label, feedback.initial)
      False -> Nil
    }
  }
  Nil
}

fn announce(feedback: Feedback, text: String) -> Nil {
  element.set_text_content(feedback.label, text)
  element.set_text_content(feedback.status, text)
}
