import components/dock_client
import features/links/link_form_client

pub fn main() -> Nil {
  dock_client.enhance()
  link_form_client.enhance()
}
