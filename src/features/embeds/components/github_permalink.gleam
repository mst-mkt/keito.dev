import components/icons
import gleam/int
import gleam/list
import gleam/string
import lib/highlight.{type Token}
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Permalink {
  Permalink(
    url: String,
    owner: String,
    repo: String,
    ref: String,
    path: String,
    lines: Lines,
    code: List(List(Token)),
  )
}

pub type Lines {
  WholeFile
  Range(start: Int, end: Int)
}

pub fn view(permalink: Permalink) -> Element(msg) {
  let start = case permalink.lines {
    WholeFile -> 1
    Range(start:, ..) -> start
  }
  let end = start + list.length(permalink.code) - 1
  let #(directory, file_name) = split_path(permalink)

  html.figure(
    [attribute.class("overflow-clip rounded-lg border border-border")],
    [
      html.figcaption(
        [attribute.class("sticky top-0 z-10 border-b border-border bg-bg")],
        [
          html.a(
            [
              attribute.href(permalink.url),
              attribute.class(
                "flex items-center gap-x-3 px-4 py-2 text-subtle -outline-offset-2 transition-colors hover:text-fg focus-visible:outline-2 focus-visible:outline-fg",
              ),
            ],
            [
              icons.github([
                attribute.aria_hidden(True),
                attribute.class("size-4 shrink-0"),
              ]),
              html.span(
                [
                  attribute.class(
                    "flex min-w-0 flex-1 flex-col gap-x-3 gap-y-0.5 sm:flex-row sm:items-baseline",
                  ),
                ],
                [
                  html.span([attribute.class("flex min-w-0 text-sm")], [
                    html.span([attribute.class("truncate")], [
                      html.text(directory),
                    ]),
                    html.span([attribute.class("shrink-0")], [html.text("/")]),
                    html.span(
                      [attribute.class("max-w-full shrink-0 truncate text-fg")],
                      [html.text(file_name)],
                    ),
                  ]),
                  html.span(
                    [attribute.class("shrink-0 font-mono text-xs sm:ml-auto")],
                    [html.text(location(permalink))],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      html.div(
        [
          attribute.class(
            "flex scrollbar-thin overflow-x-auto font-mono text-xs/5",
          ),
        ],
        [
          html.div(
            [
              attribute.aria_hidden(True),
              attribute.class(
                "sticky left-0 shrink-0 bg-bg py-3 pr-3 pl-4 text-right text-subtle select-none",
              ),
            ],
            int.range(from: end, to: start - 1, with: [], run: fn(lines, line) {
              [html.div([], [html.text(int.to_string(line))]), ..lines]
            }),
          ),
          html.pre([attribute.class("shrink-0 py-3 pr-4")], [
            html.code([], highlight.view(permalink.code)),
          ]),
        ],
      ),
    ],
  )
}

fn split_path(permalink: Permalink) -> #(String, String) {
  let #(file_name, directories) = case
    string.split(permalink.path, "/") |> list.reverse
  {
    [file_name, ..directories] -> #(file_name, list.reverse(directories))
    [] -> #(permalink.path, [])
  }

  #(
    string.join([permalink.owner, permalink.repo, ..directories], "/"),
    file_name,
  )
}

fn location(permalink: Permalink) -> String {
  let ref = case string.length(permalink.ref) {
    40 -> string.slice(permalink.ref, 0, 7)
    _ -> permalink.ref
  }

  case permalink.lines {
    WholeFile -> ref
    Range(start:, end:) -> fragment(start, end) <> " @ " <> ref
  }
}

fn fragment(start: Int, end: Int) -> String {
  case start == end {
    True -> "L" <> int.to_string(start)
    False -> "L" <> int.to_string(start) <> "-L" <> int.to_string(end)
  }
}

@internal
pub fn stories() -> List(Story) {
  let ref = "1a8a2dba8c481241cf7a8ceefe904c125ca25d71"
  let short =
    "    hotUpdate({ file, modules }) {
      const module = this.environment.moduleGraph.getModuleById(resolved);
      if (!file.endsWith(\".gleam\") || !module) return;

      return [...modules, module];
    },"
  let long =
    "  const storyModules = () => {
    return readdirSync(directory, { recursive: true, encoding: \"utf8\" })
      .filter((file) => file.endsWith(\".gleam\"))
      .filter((file) => /^pub fn stories\\(\\)/m.test(readFileSync(join(directory, file), \"utf8\")))
      .map((file) => file.slice(0, -\".gleam\".length))
      .sort();
  };"
  let single =
    "  fetch: import.meta.env.DEV ? devHandler(\"/entry/client.ts\") : handler(\"/assets/client.js\"),"
  let new = fn(variant, path, lines, code) {
    let hash = case lines {
      WholeFile -> ""
      Range(start:, end:) -> "#" <> fragment(start, end)
    }
    let permalink =
      Permalink(
        url: "https://github.com/mst-mkt/keito.dev/blob/"
          <> ref
          <> "/"
          <> path
          <> hash,
        owner: "mst-mkt",
        repo: "keito.dev",
        ref:,
        path:,
        lines:,
        code: highlight.plain(code),
      )

    story.new(variant, {
      use owner <- story.text("owner", permalink.owner)
      use repo <- story.text("repo", permalink.repo)
      use ref <- story.text("ref", permalink.ref)
      use path <- story.text("path", permalink.path)

      story.render(view(Permalink(..permalink, owner:, repo:, ref:, path:)))
    })
  }

  [
    new("default", "vite.config.ts", Range(38, 43), short),
    new("long-lines", "vite.config.ts", Range(14, 20), long),
    new("single-line", "entry/worker.ts", Range(5, 5), single),
    new(
      "long-path",
      string.repeat("long-directory/", 6) <> "long-file-name.ts",
      Range(1234, 1239),
      short,
    ),
  ]
}
