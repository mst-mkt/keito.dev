import components/text_input
import gleam/result
import plinth/browser/document
import plinth/browser/element as dom

pub fn validate_on_blur(
  name: String,
  validate: fn(String) -> Result(a, String),
) -> Nil {
  let input = document.get_element_by_id(text_input.id(name))
  let error = document.get_element_by_id(text_input.error_id(name))

  case input, error {
    Ok(input), Ok(error) -> {
      let run = fn() {
        let validated = validate(result.unwrap(dom.value(input), ""))

        dom.set_text_content(error, result.unwrap_error(validated, ""))
        dom.set_attribute(input, "aria-invalid", case validated {
          Ok(_) -> "false"
          Error(_) -> "true"
        })
      }
      let _ = dom.add_event_listener(input, "blur", fn(_) { run() })
      let _ =
        dom.add_event_listener(input, "input", fn(_) {
          case dom.get_attribute(input, "aria-invalid") {
            Ok("true") -> run()
            _ -> Nil
          }
        })

      Nil
    }
    _, _ -> Nil
  }
}
