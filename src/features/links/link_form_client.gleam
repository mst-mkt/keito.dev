import components/text_input_client
import features/links/link

pub fn enhance() -> Nil {
  text_input_client.validate_on_blur("id", link.parse_id)
  text_input_client.validate_on_blur("url", link.parse_url)
}
