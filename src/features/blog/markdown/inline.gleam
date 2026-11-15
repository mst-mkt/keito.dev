import components/icons
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/string
import lib/html_entity
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import mork/document.{
  type Destination, type Document, type Inline, Absolute, Anchor, Autolink,
  Checkbox, CodeSpan, Delim, EmailAutolink, Emphasis, Footnote, FullImage,
  FullLink, HardBreak, Highlight, InlineFootnote, InlineHtml, RawHtml, RefImage,
  RefLink, Relative, SoftBreak, Strikethrough, Strong, Text,
}

const wide =
  "^[\\p{sc=Han}\\p{sc=Hiragana}\\p{sc=Katakana}\\u3000-\\u303f\\u30fc\\uff01-\\uff60]$"

const punctuation =
  "^[\\u3000-\\u303f\\uff01-\\uff0f\\uff1a-\\uff20\\uff3b-\\uff40\\uff5b-\\uff65]$"

pub fn view(document: Document, inlines: List(Inline)) -> List(Element(msg)) {
  join_lines(inlines) |> list.map(inline_view(document, _))
}

fn join_lines(inlines: List(Inline)) -> List(Inline) {
  case inlines {
    [Text(before), SoftBreak, Text(after), ..rest] -> {
      let before = string.trim_end(before)
      let after = string.trim_start(after)
      let last = string.last(before)
      let first = string.first(after)
      let joined =
        matches(last, punctuation)
        || { matches(last, wide) && matches(first, wide) }

      case joined {
        True -> join_lines([Text(before <> after), ..rest])
        False -> [Text(before), SoftBreak, ..join_lines([Text(after), ..rest])]
      }
    }
    [inline, ..rest] -> [inline, ..join_lines(rest)]
    [] -> []
  }
}

fn matches(character: Result(String, Nil), pattern: String) -> Bool {
  let assert Ok(pattern) = regexp.from_string(pattern)

  case character {
    Ok(character) -> regexp.check(pattern, character)
    Error(Nil) -> False
  }
}

fn inline_view(document: Document, inline: Inline) -> Element(msg) {
  case inline {
    Text(text) -> html.text(html_entity.decode(text))
    CodeSpan(code) -> html.code([], [html.text(code)])
    Emphasis(inlines) -> html.em([], view(document, inlines))
    Strong(inlines) -> html.strong([], view(document, inlines))
    Strikethrough(inlines) -> html.del([], view(document, inlines))
    Highlight(inlines) -> html.mark([], view(document, inlines))
    FullLink(text:, data:) -> link(destination(data.dest), view(document, text))
    RefLink(text:, label:) ->
      case dict.get(document.links, label) {
        Ok(data) -> link(destination(data.dest), view(document, text))
        Error(Nil) -> element.fragment(view(document, text))
      }
    FullImage(text:, data:) -> image(destination(data.dest), text)
    RefImage(text:, label:) ->
      case dict.get(document.links, label) {
        Ok(data) -> image(destination(data.dest), text)
        Error(Nil) -> element.fragment(view(document, text))
      }
    Autolink(uri:, text:) -> link(uri, [html.text(option.unwrap(text, uri))])
    EmailAutolink(mail:) -> link("mailto:" <> mail, [html.text(mail)])
    Footnote(num:, ..) | InlineFootnote(num:, ..) -> {
      let number = int.to_string(num)

      html.sup([], [
        html.a(
          [
            attribute.id("fnref-" <> number),
            attribute.href("#fn-" <> number),
            attribute.aria_label("Footnote " <> number),
          ],
          [html.text(number)],
        ),
      ])
    }
    InlineHtml(children:, ..) -> element.fragment(view(document, children))
    RawHtml(raw) ->
      case string.starts_with(raw, "<!--") {
        True -> element.none()
        False -> html.text(raw)
      }
    HardBreak -> html.br([])
    SoftBreak -> html.text("\n")
    Checkbox(checked:) ->
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(checked),
        attribute.disabled(True),
      ])
    Delim(style:, len:, ..) -> html.text(string.repeat(style, len))
  }
}

fn link(href: String, children: List(Element(msg))) -> Element(msg) {
  case
    string.starts_with(href, "https://") || string.starts_with(href, "http://")
  {
    True ->
      html.a(
        [
          attribute.href(href),
          attribute.target("_blank"),
          attribute.rel("noopener"),
        ],
        list.append(children, [
          icons.arrow_up_right([attribute.aria_hidden(True)]),
          html.span([attribute.class("sr-only")], [
            html.text(" (opens in a new tab)"),
          ]),
        ]),
      )
    False -> html.a([attribute.href(href)], children)
  }
}

fn image(src: String, text: List(Inline)) -> Element(msg) {
  html.img([
    attribute.src(src),
    attribute.alt(plain_text(text)),
    attribute.loading("lazy"),
  ])
}

fn destination(destination: Destination) -> String {
  case destination {
    Absolute(uri:) | Relative(uri:) -> uri
    Anchor(id:) -> "#" <> id
  }
}

pub fn plain_text(inlines: List(Inline)) -> String {
  list.map(inlines, fn(inline) {
    case inline {
      Text(text) -> html_entity.decode(text)
      CodeSpan(text) | RawHtml(text) -> text
      Emphasis(inlines)
      | Strong(inlines)
      | Strikethrough(inlines)
      | Highlight(inlines)
      | FullLink(text: inlines, ..)
      | RefLink(text: inlines, ..)
      | FullImage(text: inlines, ..)
      | RefImage(text: inlines, ..)
      | InlineHtml(children: inlines, ..) -> plain_text(inlines)
      Autolink(uri:, text:) -> option.unwrap(text, uri)
      EmailAutolink(mail:) -> mail
      SoftBreak | HardBreak -> " "
      Delim(style:, len:, ..) -> string.repeat(style, len)
      Footnote(..) | InlineFootnote(..) | Checkbox(..) -> ""
    }
  })
  |> string.concat
}
