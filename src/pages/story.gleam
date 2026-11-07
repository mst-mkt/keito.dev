import components/icons
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/javascript/array.{type Array}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/result
import gleam/string
import gleam/uri
import hinoto/body.{type Body}
import layouts/base
import lib/cn.{cn}
import lib/story.{type Module, type Route, type Story, Canvas, Docs, Show}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html
import pages/not_found
import server/context.{type Context}
import server/middleware
import server/respond

const viewport_param = "viewport"

const default_viewport = #("fit", 0)

const viewports = [
  default_viewport,
  #("desktop", 1440),
  #("tablet", 768),
  #("mobile", 390),
]

const scheme_param = "scheme"

const default_scheme = "system"

const schemes = [default_scheme, "light", "dark"]

const global_params = [viewport_param, scheme_param]

const focus_ring =
  "outline-0 outline-fg/25 outline-solid focus-visible:outline-3"

const control_class = [
  "bg-control hover:bg-control-hover",
  focus_ring,
  "transition-[background-color,outline-width] duration-100 ease-out",
]

type Globals {
  Globals(viewport: #(String, Int), scheme: String)
}

type NavModule {
  NavModule(
    directory: String,
    label: String,
    name: String,
    stories: List(Story),
  )
}

@external(javascript, "virtual:stories", "modules")
fn story_modules() -> Array(Module)

pub fn handle(
  req: Request(Body),
  context: Context,
  segments: List(String),
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  let modules = array.to_list(story_modules())
  let query = request.get_query(req) |> result.unwrap([])

  case segments, modules, story.resolve(modules, segments) {
    _, [], _ -> not_found.handle(req, context)
    [], [#(module, _), ..], _ ->
      promise.resolve(respond.redirect(302, story.docs_path(module)))
    _, _, Ok(resolved) ->
      promise.resolve(respond.html(200, view(context, modules, resolved, query)))
    _, _, Error(Nil) -> promise.resolve(respond.redirect(302, "/story"))
  }
}

fn view(
  context: Context,
  modules: List(Module),
  resolved: Route,
  query: List(#(String, String)),
) -> Element(Nil) {
  let globals = parse_globals(query)
  let carry =
    to_query(list.append(viewport_params(globals), scheme_params(globals)))

  case resolved {
    Docs(module:, stories:) ->
      base.shell(module, context.client_entry, head: [], body: [
        view_layout(
          modules,
          module,
          story.docs_path(module),
          carry,
          view_docs(module, stories, globals, carry),
        ),
      ])
    Show(module:, story: entry) ->
      base.shell(
        module <> "/" <> story.name(entry),
        context.client_entry,
        head: [],
        body: [
          view_layout(
            modules,
            module,
            story.path(module, entry),
            carry,
            view_story(module, entry, query, globals, carry),
          ),
        ],
      )
    Canvas(story: entry) -> {
      let #(element, _) = story.run(entry, query)

      let head = case globals.scheme == default_scheme {
        True -> []
        False -> [
          html.style([], ":root { color-scheme: " <> globals.scheme <> "; }"),
        ]
      }

      base.shell(story.name(entry), context.client_entry, head:, body: [
        html.main([attribute.class("p-8")], [element]),
      ])
    }
  }
}

fn parse_globals(query: List(#(String, String))) -> Globals {
  let viewport =
    list.key_find(query, viewport_param)
    |> result.try(fn(name) {
      list.find(viewports, fn(viewport) { viewport.0 == name })
    })
    |> result.unwrap(default_viewport)
  let scheme =
    list.key_find(query, scheme_param)
    |> result.try(fn(name) { list.find(schemes, fn(scheme) { scheme == name }) })
    |> result.unwrap(default_scheme)

  Globals(viewport:, scheme:)
}

fn viewport_params(globals: Globals) -> List(#(String, String)) {
  case globals.viewport == default_viewport {
    True -> []
    False -> [#(viewport_param, globals.viewport.0)]
  }
}

fn scheme_params(globals: Globals) -> List(#(String, String)) {
  case globals.scheme == default_scheme {
    True -> []
    False -> [#(scheme_param, globals.scheme)]
  }
}

fn to_query(params: List(#(String, String))) -> String {
  case params {
    [] -> ""
    _ -> "?" <> uri.query_to_string(params)
  }
}

fn color_scheme(globals: Globals) -> Attribute(Nil) {
  case globals.scheme == default_scheme {
    True -> attribute.none()
    False -> attribute.style("color-scheme", globals.scheme)
  }
}

fn view_layout(
  modules: List(Module),
  current_module: String,
  current_path: String,
  carry: String,
  content: List(Element(Nil)),
) -> Element(Nil) {
  html.div([attribute.class("flex h-dvh")], [
    view_sidebar(modules, current_module, current_path, carry),
    ..content
  ])
}

fn view_docs(
  module: String,
  stories: List(Story),
  globals: Globals,
  carry: String,
) -> List(Element(Nil)) {
  [
    html.main(
      [
        attribute.class(
          cn([
            "grid min-w-0 flex-1 content-start gap-y-10 p-8",
            "scrollbar-thin overflow-y-auto",
          ]),
        ),
      ],
      [
        html.h1([attribute.class("text-2xl font-bold")], [html.text(module)]),
        ..list.map(stories, fn(entry) {
          let path = story.path(module, entry)

          html.section([attribute.class("grid max-w-3xl gap-y-3")], [
            html.h2([], [
              html.a(
                [
                  attribute.href(path <> carry),
                  attribute.class(
                    cn(["rounded-xs font-medium hover:underline", focus_ring]),
                  ),
                ],
                [html.text(story.name(entry))],
              ),
            ]),
            view_preview(path, entry, globals),
          ])
        })
      ],
    ),
  ]
}

fn view_preview(path: String, entry: Story, globals: Globals) -> Element(Nil) {
  case story.is_isolated(entry) {
    True ->
      html.iframe([
        attribute.src(path <> "/canvas" <> to_query(scheme_params(globals))),
        color_scheme(globals),
        attribute.title(story.name(entry)),
        attribute.class("h-64 w-full resize-y rounded-lg border border-border"),
      ])
    False ->
      html.div(
        [
          attribute.class(
            "min-w-0 rounded-lg border border-border bg-bg p-8 text-fg accent-fg",
          ),
          color_scheme(globals),
        ],
        [story.run(entry, []).0],
      )
  }
}

fn view_story(
  module: String,
  entry: Story,
  query: List(#(String, String)),
  globals: Globals,
  carry: String,
) -> List(Element(Nil)) {
  let path = story.path(module, entry)
  let #(_, controls) = story.run(entry, query)
  let story_query =
    list.filter(query, fn(param) { !list.contains(global_params, param.0) })
  let canvas =
    path
    <> "/canvas"
    <> to_query(list.append(story_query, scheme_params(globals)))

  [
    html.main([attribute.class("flex min-w-0 flex-1 flex-col bg-control")], [
      html.header(
        [
          attribute.class(
            cn([
              "flex h-12 shrink-0 items-center gap-x-4 px-4 text-sm",
              "border-b border-border",
            ]),
          ),
        ],
        [
          html.h1(
            [attribute.class("flex min-w-0 items-baseline gap-x-1 text-subtle")],
            [
              html.a(
                [
                  attribute.href(story.docs_path(module) <> carry),
                  attribute.class(
                    cn([
                      "min-w-0 truncate rounded-xs hover:text-fg hover:underline",
                      focus_ring,
                    ]),
                  ),
                ],
                [html.text(module)],
              ),
              html.span([attribute.aria_hidden(True)], [html.text("/")]),
              html.span(
                [attribute.class("min-w-0 truncate font-medium text-fg")],
                [
                  html.text(story.name(entry)),
                ],
              ),
            ],
          ),
          html.a(
            [
              attribute.href(canvas),
              attribute.target("_blank"),
              attribute.class(
                cn([
                  "ml-auto inline-flex shrink-0 items-center gap-x-1 rounded-xs text-subtle hover:text-fg",
                  focus_ring,
                ]),
              ),
            ],
            [
              html.text("Open canvas"),
              icons.open_new_window([
                attribute.aria_hidden(True),
                attribute.class("size-4"),
              ]),
            ],
          ),
        ],
      ),
      html.div(
        [
          attribute.class(
            "flex min-h-0 flex-1 scrollbar-thin overflow-auto p-4",
          ),
        ],
        [
          html.iframe([
            attribute.src(canvas),
            color_scheme(globals),
            attribute.title(story.name(entry)),
            attribute.style("width", case globals.viewport.1 {
              0 -> "100%"
              width -> int.to_string(width) <> "px"
            }),
            attribute.class(
              "mx-auto shrink-0 rounded-lg border border-border bg-bg",
            ),
          ]),
        ],
      ),
    ]),
    html.form(
      [
        attribute.method("get"),
        attribute.action(path),
        attribute.aria_label("Controls"),
        attribute.attribute("onchange", "this.requestSubmit()"),
        attribute.class(
          cn([
            "grid w-72 shrink-0 content-start gap-y-6 p-4",
            "border-l border-border",
            "scrollbar-thin overflow-y-auto",
          ]),
        ),
      ],
      [
        html.div([attribute.class("grid gap-y-6 border-b border-border pb-6")], [
          view_select(
            viewport_param,
            globals.viewport.0,
            list.map(viewports, fn(viewport) { viewport.0 }),
          ),
          view_select(scheme_param, globals.scheme, schemes),
        ]),
        ..list.map(controls, view_control)
      ],
    ),
  ]
}

fn view_sidebar(
  modules: List(Module),
  current_module: String,
  current_path: String,
  carry: String,
) -> Element(Nil) {
  let groups =
    list.map(modules, to_nav_module)
    |> list.sort(fn(a, b) { string.compare(a.directory, b.directory) })
    |> list.chunk(fn(nav_module) { nav_module.directory })

  html.nav(
    [
      attribute.id(story.nav_id),
      attribute.aria_label("Stories"),
      attribute.class(
        cn([
          "w-56 shrink-0 border-r border-border p-3 text-sm wrap-anywhere",
          "scrollbar-thin overflow-y-auto overscroll-contain",
        ]),
      ),
    ],
    [
      html.ul(
        [attribute.class("grid gap-y-4")],
        list.filter_map(groups, fn(group) {
          use first <- result.map(list.first(group))

          html.li([attribute.class("grid gap-y-0.5")], [
            html.h2(
              [attribute.class("px-1.5 py-1 text-xs font-medium text-subtle")],
              [html.text(first.directory)],
            ),
            html.ul(
              [attribute.class("grid gap-y-1")],
              list.map(group, view_nav_module(
                _,
                current_module,
                current_path,
                carry,
              )),
            ),
          ])
        }),
      ),
    ],
  )
}

fn view_nav_module(
  nav_module: NavModule,
  current_module: String,
  current_path: String,
  carry: String,
) -> Element(Nil) {
  let docs_path = story.docs_path(nav_module.name)

  html.li([], [
    html.details(
      [
        attribute.open(nav_module.name == current_module),
        attribute.data("module", nav_module.name),
        attribute.class("group grid gap-y-0.5 open:pb-2"),
      ],
      [
        html.summary(
          [
            attribute.class(
              cn([
                "flex cursor-pointer list-none items-center rounded-md pl-1.5",
                "[&::-webkit-details-marker]:hidden",
                "hover:bg-control-hover has-aria-[current=page]:bg-control",
                focus_ring,
              ]),
            ),
          ],
          [
            icons.nav_arrow_down([
              attribute.aria_hidden(True),
              attribute.class(
                "size-3.5 shrink-0 -rotate-90 text-subtle group-open:rotate-0",
              ),
            ]),
            html.a(
              [
                attribute.href(docs_path <> carry),
                aria_current(docs_path, current_path),
                attribute.class(
                  cn([
                    "flex-1 rounded-md py-1 pr-1.5 pl-1 font-medium",
                    focus_ring,
                  ]),
                ),
              ],
              [html.text(nav_module.label)],
            ),
          ],
        ),
        html.ul(
          [
            attribute.class("ml-3 grid gap-y-0.5 border-l border-border pl-3"),
          ],
          list.map(nav_module.stories, fn(entry) {
            let path = story.path(nav_module.name, entry)

            html.li([], [
              html.a(
                [
                  attribute.href(path <> carry),
                  aria_current(path, current_path),
                  attribute.class(
                    cn([
                      "block rounded-md px-1.5 py-1 text-muted",
                      "hover:bg-control-hover hover:text-fg",
                      "aria-[current=page]:bg-control aria-[current=page]:font-medium aria-[current=page]:text-fg",
                      focus_ring,
                    ]),
                  ),
                ],
                [html.text(story.name(entry))],
              ),
            ])
          }),
        ),
      ],
    ),
  ])
}

fn aria_current(href: String, current_path: String) -> Attribute(Nil) {
  case href == current_path {
    True -> attribute.aria_current("page")
    False -> attribute.none()
  }
}

fn to_nav_module(module: Module) -> NavModule {
  let #(name, stories) = module

  case list.reverse(string.split(name, "/")) {
    [label, ..directory] ->
      NavModule(
        directory: string.join(list.reverse(directory), "/"),
        label:,
        name:,
        stories:,
      )
    [] -> NavModule(directory: "", label: name, name:, stories:)
  }
}

fn view_control(control: story.Control) -> Element(Nil) {
  case control {
    story.Text(name:, value:) ->
      view_field(name, [
        html.input([
          attribute.type_("text"),
          attribute.id(name),
          attribute.name(name),
          attribute.value(value),
          attribute.class(cn(["h-9 rounded-md px-3", ..control_class])),
        ]),
      ])
    story.Number(name:, value:) ->
      view_field(name, [
        html.input([
          attribute.type_("number"),
          attribute.id(name),
          attribute.name(name),
          attribute.value(int.to_string(value)),
          attribute.class(cn(["h-9 rounded-md px-3", ..control_class])),
        ]),
      ])
    story.Bool(name:, value:) ->
      html.label([attribute.class("flex items-center gap-x-2 text-sm")], [
        html.input([
          attribute.type_("hidden"),
          attribute.name(name),
          attribute.value("false"),
        ]),
        html.input([
          attribute.type_("checkbox"),
          attribute.name(name),
          attribute.value("true"),
          attribute.checked(value),
        ]),
        html.text(name),
      ])
    story.Select(name:, value:, options:) -> view_select(name, value, options)
  }
}

fn view_select(
  name: String,
  value: String,
  options: List(String),
) -> Element(Nil) {
  view_field(name, [
    html.select(
      [
        attribute.id(name),
        attribute.name(name),
        attribute.class(cn(["h-9 rounded-md px-2", ..control_class])),
      ],
      list.map(options, fn(option) {
        html.option(
          [attribute.value(option), attribute.selected(option == value)],
          option,
        )
      }),
    ),
  ])
}

fn view_field(name: String, input: List(Element(Nil))) -> Element(Nil) {
  html.div([attribute.class("grid gap-y-1")], [
    html.label([attribute.for(name), attribute.class("text-sm text-muted")], [
      html.text(name),
    ]),
    ..input
  ])
}
