import features/blog/markdown/code
import features/blog/markdown/heading.{type Ids}
import features/blog/markdown/inline
import features/blog/markdown/table
import features/blog/markdown/tag
import features/embeds/embed.{type Embed}
import gleam/bool
import gleam/dict
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import mork
import mork/document.{
  type Block, type Document, type Inline, type ListItem, type ListPack,
  BlockQuote, BulletList, Code, Emphasis, Empty, FullImage, Heading, HtmlBlock,
  Loose, Newline, OrderedList, Paragraph, RawHtml, RefImage, SoftBreak, Table,
  Text, ThematicBreak, Tight,
}

type Renderer(msg) {
  Renderer(document: Document, embed_view: fn(Embed) -> Promise(Element(msg)))
}

pub fn render(
  markdown: String,
  embed_view: fn(Embed) -> Promise(Element(msg)),
) -> Promise(List(Element(msg))) {
  let document =
    mork.configure()
    |> mork.strip_frontmatter(True)
    |> mork.tables(True)
    |> mork.tasklists(True)
    |> mork.autolinks(True)
    |> mork.parse_with_options(markdown)
  let renderer = Renderer(document:, embed_view:)
  let #(ids, blocks) = blocks_view(renderer, dict.new(), document.blocks, Loose)
  let notes = footnotes(renderer, ids)
  use blocks <- promise.await(blocks)
  use notes <- promise.map(notes)

  list.append(blocks, notes)
}

fn blocks_view(
  renderer: Renderer(msg),
  ids: Ids,
  blocks: List(Block),
  pack: ListPack,
) -> #(Ids, Promise(List(Element(msg)))) {
  let #(ids, blocks) =
    list.map_fold(blocks, ids, fn(ids, block) {
      block_view(renderer, ids, block, pack)
    })

  #(ids, promise.await_list(blocks) |> promise.map(list.flatten))
}

fn block_view(
  renderer: Renderer(msg),
  ids: Ids,
  block: Block,
  pack: ListPack,
) -> #(Ids, Promise(List(Element(msg)))) {
  case block {
    Heading(level:, inlines:, ..) -> {
      let #(ids, id) = heading.id(ids, inlines)
      let heading = heading.view(renderer.document, level, id, inlines)

      #(ids, promise.resolve([heading]))
    }
    BlockQuote(blocks) -> {
      let #(ids, blocks) = blocks_view(renderer, ids, blocks, Loose)

      #(ids, promise.map(blocks, fn(blocks) { [html.blockquote([], blocks)] }))
    }
    BulletList(pack:, items:) -> {
      let #(ids, items) = items_view(renderer, ids, items, pack)

      #(ids, promise.map(items, fn(items) { [html.ul([], items)] }))
    }
    OrderedList(pack:, items:, start:) -> {
      let start = case start {
        Some(start) -> [attribute.attribute("start", int.to_string(start))]
        None -> []
      }
      let #(ids, items) = items_view(renderer, ids, items, pack)

      #(ids, promise.map(items, fn(items) { [html.ol(start, items)] }))
    }
    Paragraph(inlines:, ..) -> #(ids, paragraph(renderer, inlines, pack))
    Code(lang:, text:) -> {
      let block = code.view(lang, text) |> promise.map(list.wrap)

      #(ids, block)
    }
    HtmlBlock(raw) -> #(ids, html_block(renderer, raw))
    Table(header:, rows:) -> {
      let table = table.view(renderer.document, header, rows)

      #(ids, promise.resolve([table]))
    }
    ThematicBreak -> #(ids, promise.resolve([html.hr([])]))
    Newline | Empty -> #(ids, promise.resolve([]))
  }
}

fn items_view(
  renderer: Renderer(msg),
  ids: Ids,
  items: List(ListItem),
  pack: ListPack,
) -> #(Ids, Promise(List(Element(msg)))) {
  let #(ids, items) =
    list.map_fold(items, ids, fn(ids, item) {
      let #(ids, blocks) = blocks_view(renderer, ids, item.blocks, pack)

      #(ids, promise.map(blocks, html.li([], _)))
    })

  #(ids, promise.await_list(items))
}

fn paragraph(
  renderer: Renderer(msg),
  inlines: List(Inline),
  pack: ListPack,
) -> Promise(List(Element(msg))) {
  let document = renderer.document

  case list.filter(inlines, fn(inline) { inline != Text("") }) {
    [RawHtml(raw)] -> html_block(renderer, raw)
    [FullImage(..) as image, SoftBreak, Emphasis(caption)]
    | [RefImage(..) as image, SoftBreak, Emphasis(caption)] -> {
      let image = inline.view(document, [image])
      let caption = html.figcaption([], inline.view(document, caption))

      promise.resolve([html.figure([], list.append(image, [caption]))])
    }
    inlines ->
      case pack {
        Tight -> promise.resolve(inline.view(document, inlines))
        Loose -> promise.resolve([html.p([], inline.view(document, inlines))])
      }
  }
}

fn html_block(
  renderer: Renderer(msg),
  raw: String,
) -> Promise(List(Element(msg))) {
  use <- bool.guard(string.starts_with(raw, "<!--"), promise.resolve([]))
  let raw = string.trim(raw)
  let embedded = {
    use #(name, attributes) <- result.try(
      tag.parse(raw) |> result.replace_error(raw <> " is not an embed."),
    )

    embed.from_tag(name, attributes)
  }

  case embedded {
    Ok(embedded) -> renderer.embed_view(embedded) |> promise.map(list.wrap)
    Error(message) ->
      promise.resolve([
        html.p([attribute.class("text-sm text-danger")], [html.text(message)]),
      ])
  }
}

fn footnotes(renderer: Renderer(msg), ids: Ids) -> Promise(List(Element(msg))) {
  let notes =
    dict.values(renderer.document.footnotes)
    |> list.sort(fn(a, b) { int.compare(a.num, b.num) })
  use <- bool.guard(notes == [], promise.resolve([]))
  let #(_, items) =
    list.map_fold(notes, ids, fn(ids, note) {
      let number = int.to_string(note.num)
      let back =
        html.a(
          [
            attribute.href("#fnref-" <> number),
            attribute.aria_label("Back to reference " <> number),
          ],
          [html.text("↩\u{FE0E}")],
        )
      let #(ids, blocks) = blocks_view(renderer, ids, note.blocks, Loose)
      let item =
        promise.map(blocks, fn(blocks) {
          html.li([attribute.id("fn-" <> number)], list.append(blocks, [back]))
        })

      #(ids, item)
    })
  use items <- promise.map(promise.await_list(items))

  [html.section([attribute.aria_label("Footnotes")], [html.ol([], items)])]
}
