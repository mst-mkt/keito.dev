import components/dock_client
import features/links/link_form_client
import features/links/nfc_client
import pages/story_client

pub fn main() -> Nil {
  dock_client.enhance()
  link_form_client.enhance()
  nfc_client.enhance()
  story_client.enhance()
}
