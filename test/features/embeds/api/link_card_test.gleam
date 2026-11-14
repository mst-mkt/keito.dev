import features/embeds/api/link_card as api
import features/embeds/components/link_card.{type LinkCard, LinkCard}
import gleam/json
import gleam/option.{None, Some}
import lib/html_head.{type Head, type Meta, Head, Link, Meta}

const url = "https://www.example.com/posts/1"

fn decode(head: Head) -> Result(LinkCard, json.DecodeError) {
  json.parse(api.encode_head(head), api.decoder(url))
}

fn empty() -> Head {
  Head(base: None, titles: [], metas: [], links: [])
}

fn property(property: String, content: String) -> Meta {
  Meta(name: None, property: Some(property), content: Some(content))
}

pub fn decoder_og_title_test() {
  let head =
    Head(..empty(), titles: ["Title"], metas: [property("og:title", "OG")])

  let assert Ok(LinkCard(title:, ..)) = decode(head)

  assert title == "OG"
}

pub fn decoder_first_title_test() {
  let head = Head(..empty(), titles: ["Title", "Other"])

  let assert Ok(LinkCard(title:, ..)) = decode(head)

  assert title == "Title"
}

pub fn decoder_trimmed_title_test() {
  let head = Head(..empty(), titles: ["\n  Title\n"])

  let assert Ok(LinkCard(title:, ..)) = decode(head)

  assert title == "Title"
}

pub fn decoder_untitled_test() {
  let head = empty()

  let assert Ok(LinkCard(title:, ..)) = decode(head)

  assert title == url
}

pub fn decoder_empty_og_title_test() {
  let head =
    Head(..empty(), titles: ["Title"], metas: [property("og:title", "")])

  let assert Ok(LinkCard(title:, ..)) = decode(head)

  assert title == "Title"
}

pub fn decoder_meta_name_test() {
  let head =
    Head(..empty(), metas: [
      Meta(name: Some("description"), property: None, content: Some("Text")),
    ])

  let assert Ok(LinkCard(description:, ..)) = decode(head)

  assert description == Some("Text")
}

pub fn decoder_html_entity_test() {
  let head = Head(..empty(), metas: [property("og:title", "A &amp; B")])

  let assert Ok(LinkCard(title:, ..)) = decode(head)

  assert title == "A & B"
}

pub fn decoder_relative_image_test() {
  let head = Head(..empty(), metas: [property("og:image", "/ogp.png")])

  let assert Ok(LinkCard(image:, ..)) = decode(head)

  assert image == Some("https://www.example.com/ogp.png")
}

pub fn decoder_image_base_test() {
  let head =
    Head(..empty(), base: Some("/assets/"), metas: [
      property("og:image", "ogp.png"),
    ])

  let assert Ok(LinkCard(image:, ..)) = decode(head)

  assert image == Some("https://www.example.com/assets/ogp.png")
}

pub fn decoder_shortcut_icon_test() {
  let head =
    Head(..empty(), links: [
      Link(rel: Some("Shortcut Icon"), href: Some("/favicon.ico")),
    ])

  let assert Ok(LinkCard(icon:, ..)) = decode(head)

  assert icon == Some("https://www.example.com/favicon.ico")
}

pub fn decoder_stylesheet_link_test() {
  let head =
    Head(..empty(), links: [
      Link(rel: Some("stylesheet"), href: Some("/style.css")),
    ])

  let assert Ok(LinkCard(icon:, ..)) = decode(head)

  assert icon == None
}

pub fn decoder_uppercase_meta_test() {
  let head = Head(..empty(), metas: [property("OG:Title", "OG")])

  let assert Ok(LinkCard(title:, ..)) = decode(head)

  assert title == "OG"
}

pub fn decoder_site_from_host_test() {
  let head = empty()

  let assert Ok(LinkCard(site:, ..)) = decode(head)

  assert site == "www.example.com"
}
