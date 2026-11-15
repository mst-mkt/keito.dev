import components/icons
import features/blog/embed.{LinkCard}
import features/blog/markdown.{Section}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html

fn render(markdown: String) -> Promise(String) {
  let embed_view = fn(embed) {
    case embed {
      LinkCard(url:) -> html.a([attribute.href(url)], [])
      _ -> element.none()
    }
    |> promise.resolve
  }
  use elements <- promise.map(markdown.render(markdown, embed_view))

  list.map(elements, element.to_string) |> string.concat
}

fn heading(id: String) -> String {
  let anchor = icons.hashtag([attribute.aria_hidden(True)])

  "<h2 id=\""
  <> id
  <> "\"><span>Heading</span><a aria-label=\"Link to Heading\" href=\"#"
  <> id
  <> "\">"
  <> element.to_string(anchor)
  <> "</a></h2>"
}

pub fn embeds_test() {
  let markdown =
    "<LinkCard url=\"https://example.com/a\" />\n\n> <LinkCard url=\"https://example.com/b\" />\n\n<LinkCard />\n"

  let embeds = markdown.embeds(markdown)

  assert embeds
    == [LinkCard("https://example.com/a"), LinkCard("https://example.com/b")]
}

pub fn sections_test() {
  let markdown = "## A\n\n### B\n\n> ## A\n\n## A\n"

  let sections = markdown.sections(markdown)

  assert sections
    == [
      Section(level: 2, id: "a", title: "A"),
      Section(level: 3, id: "b", title: "B"),
      Section(level: 2, id: "a-1", title: "A"),
      Section(level: 2, id: "a-2", title: "A"),
    ]
}

pub fn render_duplicate_headings_test() {
  let markdown = "## Heading\n\n## Heading\n"

  use html <- promise.map(render(markdown))

  assert html == heading("heading") <> heading("heading-1")
}

pub fn render_nested_duplicate_headings_test() {
  let markdown = "## Heading\n\n> ## Heading\n"

  use html <- promise.map(render(markdown))

  assert html
    == heading("heading")
    <> "<blockquote>"
    <> heading("heading-1")
    <> "</blockquote>"
}

pub fn render_soft_break_between_wide_characters_test() {
  let markdown = "あ\nい\n"

  use html <- promise.map(render(markdown))

  assert html == "<p>あい</p>"
}

pub fn render_soft_break_after_punctuation_test() {
  let markdown = "あ。\na\n"

  use html <- promise.map(render(markdown))

  assert html == "<p>あ。a</p>"
}

pub fn render_soft_break_next_to_ascii_test() {
  let markdown = "あ\na\n"

  use html <- promise.map(render(markdown))

  assert html == "<p>あ\na</p>"
}

pub fn render_tight_list_test() {
  let markdown = "- a\n- b\n"

  use html <- promise.map(render(markdown))

  assert html == "<ul><li>a</li><li>b</li></ul>"
}

pub fn render_loose_list_test() {
  let markdown = "- a\n\n- b\n"

  use html <- promise.map(render(markdown))

  assert html == "<ul><li><p>a</p></li><li><p>b</p></li></ul>"
}

pub fn render_table_test() {
  let markdown = "| a |\n| :-: |\n| b |\n"

  use html <- promise.map(render(markdown))

  assert html
    == "<div class=\"overflow-x-auto\" tabindex=\"0\"><table><thead><tr><th style=\"text-align:center;\">a</th></tr></thead><tbody><tr><td style=\"text-align:center;\">b</td></tr></tbody></table></div>"
}

pub fn render_code_block_title_test() {
  let markdown = "```ts title=\"index.ts\"\na\n```\n"

  use html <- promise.map(render(markdown))

  assert html
    == "<figure><figcaption>index.ts</figcaption><pre class=\"overflow-x-auto\" tabindex=\"0\"><code>a</code></pre></figure>"
}

pub fn render_image_caption_test() {
  let markdown = "![a](https://example.com/a.png)\n_b_\n"

  use html <- promise.map(render(markdown))

  assert html
    == "<figure><img alt=\"a\" loading=\"lazy\" src=\"https://example.com/a.png\"><figcaption>b</figcaption></figure>"
}

pub fn render_external_link_test() {
  let markdown = "[a](https://example.com)\n"
  let icon = icons.arrow_up_right([attribute.aria_hidden(True)])

  use html <- promise.map(render(markdown))

  assert html
    == "<p><a href=\"https://example.com\" rel=\"noopener\" target=\"_blank\">a"
    <> element.to_string(icon)
    <> "<span class=\"sr-only\"> (opens in a new tab)</span></a></p>"
}

pub fn render_internal_link_test() {
  let markdown = "[a](/b)\n"

  use html <- promise.map(render(markdown))

  assert html == "<p><a href=\"/b\">a</a></p>"
}

pub fn render_embed_test() {
  let markdown = "<LinkCard url=\"https://example.com\" />\n"

  use html <- promise.map(render(markdown))

  assert html == "<a href=\"https://example.com\"></a>"
}

pub fn render_multiline_embed_test() {
  let markdown = "<LinkCard\n  url=\"https://example.com\"\n/>\n"

  use html <- promise.map(render(markdown))

  assert html == "<a href=\"https://example.com\"></a>"
}

pub fn render_embed_without_url_test() {
  let markdown = "<LinkCard />\n"

  use html <- promise.map(render(markdown))

  assert html
    == "<p class=\"text-sm text-danger\">&lt;LinkCard&gt; requires a url attribute.</p>"
}

pub fn render_non_embed_html_test() {
  let markdown = "<div>\n</div>\n"

  use html <- promise.map(render(markdown))

  assert html
    == "<p class=\"text-sm text-danger\">&lt;div&gt;\n&lt;/div&gt; is not an embed.</p>"
}

pub fn render_html_comment_test() {
  let markdown = "<!-- a -->\n\nb <!-- c -->\n"

  use html <- promise.map(render(markdown))

  assert html == "<p>b </p>"
}

pub fn render_inline_html_test() {
  let markdown = "a <b>b</b>\n"

  use html <- promise.map(render(markdown))

  assert html == "<p>a &lt;b&gt;b&lt;/b&gt;</p>"
}

pub fn render_footnote_test() {
  let markdown = "a[^1]\n\n[^1]: b\n"
  let back = icons.long_arrow_up_left([attribute.aria_hidden(True)])

  use html <- promise.map(render(markdown))

  assert html
    == "<p>a<sup><a aria-label=\"Footnote 1\" href=\"#fn-1\" id=\"fnref-1\">1</a></sup></p><section aria-label=\"Footnotes\"><ol><li id=\"fn-1\"><p>b</p><a aria-label=\"Back to reference 1\" href=\"#fnref-1\">"
    <> element.to_string(back)
    <> "</a></li></ol></section>"
}
