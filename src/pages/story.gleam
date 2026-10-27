import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/array.{type Array}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/result
import gleam/uri
import hinoto/body.{type Body}
import layouts/base
import lib/story.{type Module, type Route, type Story, Canvas, Docs, Show}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import pages/not_found
import server/context.{type Context}
import server/middleware
import server/respond

const default_viewport = #("desktop", "1440px")

const viewports = [default_viewport, #("tablet", "768px"), #("mobile", "390px")]

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
    [], [#(module, _), ..], _ ->
      promise.resolve(respond.redirect(302, story.docs_path(module)))
    _, _, Ok(resolved) ->
      promise.resolve(respond.html(200, view(context, modules, resolved, query)))
    _, _, Error(Nil) -> not_found.handle(req, context)
  }
}

fn view(
  context: Context,
  modules: List(Module),
  resolved: Route,
  query: List(#(String, String)),
) -> Element(Nil) {
  case resolved {
    Docs(module:, stories:) ->
      base.shell(module, context.client_entry, [
        view_layout(
          modules,
          story.docs_path(module),
          view_docs(module, stories),
        ),
      ])
    Show(module:, story:) ->
      base.shell(module <> "/" <> story.name(story), context.client_entry, [
        view_layout(
          modules,
          story.path(module, story),
          view_story(module, story, query),
        ),
      ])
    Canvas(story:) -> {
      let #(element, _) = story.run(story, query)

      base.shell(story.name(story), context.client_entry, [
        html.main([attribute.class("p-8")], [element]),
      ])
    }
  }
}

fn view_layout(
  modules: List(Module),
  current: String,
  content: List(Element(Nil)),
) -> Element(Nil) {
  html.div([attribute.class("flex h-dvh")], [
    view_sidebar(modules, current),
    ..content
  ])
}

fn view_docs(module: String, stories: List(Story)) -> List(Element(Nil)) {
  [
    html.main(
      [
        attribute.class(
          "grid flex-1 content-start gap-y-10 overflow-y-auto p-8",
        ),
      ],
      [
        html.h1([attribute.class("text-2xl font-bold")], [html.text(module)]),
        ..list.map(stories, fn(story) {
          let path = story.path(module, story)

          html.section([attribute.class("grid gap-y-3")], [
            html.h2([], [
              html.a(
                [
                  attribute.href(path),
                  attribute.class("font-medium hover:underline"),
                ],
                [html.text(story.name(story))],
              ),
            ]),
            html.iframe([
              attribute.src(path <> "/canvas"),
              attribute.title(story.name(story)),
              attribute.class(
                "h-64 w-full resize-y overflow-auto rounded-lg border border-border",
              ),
            ]),
          ])
        })
      ],
    ),
  ]
}

fn view_story(
  module: String,
  story: Story,
  query: List(#(String, String)),
) -> List(Element(Nil)) {
  let path = story.path(module, story)
  let #(_, controls) = story.run(story, query)
  let #(viewport, width) =
    list.key_find(query, "viewport")
    |> result.try(fn(name) {
      list.find(viewports, fn(viewport) { viewport.0 == name })
    })
    |> result.unwrap(default_viewport)
  let story_query = list.filter(query, fn(param) { param.0 != "viewport" })

  [
    html.main([attribute.class("flex-1 overflow-auto bg-control p-4")], [
      html.h1([attribute.class("sr-only")], [html.text(story.name(story))]),
      html.iframe([
        attribute.src(path <> "/canvas?" <> uri.query_to_string(story_query)),
        attribute.title(story.name(story)),
        attribute.style("width", width),
        attribute.class(
          "mx-auto block h-full rounded-lg border border-border bg-bg",
        ),
      ]),
    ]),
    html.form(
      [
        attribute.method("get"),
        attribute.action(path),
        attribute.attribute("onchange", "this.requestSubmit()"),
        attribute.class(
          "grid w-72 shrink-0 content-start gap-y-6 overflow-y-auto border-l border-border p-4",
        ),
      ],
      [
        view_select("viewport", viewport, list.map(viewports, fn(v) { v.0 })),
        ..list.map(controls, view_control)
      ],
    ),
  ]
}

fn view_sidebar(modules: List(Module), current: String) -> Element(Nil) {
  html.nav(
    [
      attribute.aria_label("Stories"),
      attribute.class(
        "w-56 shrink-0 overflow-y-auto border-r border-border p-4",
      ),
    ],
    [
      html.ul(
        [attribute.class("grid gap-y-6")],
        list.map(modules, fn(module) {
          let #(name, stories) = module

          html.li([attribute.class("grid gap-y-1")], [
            view_link(
              story.docs_path(name),
              current,
              "px-2 py-1 text-xs font-medium text-subtle hover:text-fg aria-[current=page]:text-fg",
              name,
            ),
            html.ul(
              [attribute.class("grid gap-y-0.5")],
              list.map(stories, fn(story) {
                html.li([], [
                  view_link(
                    story.path(name, story),
                    current,
                    "px-2 py-1.5 text-sm hover:bg-control-hover aria-[current=page]:bg-control aria-[current=page]:font-medium",
                    story.name(story),
                  ),
                ])
              }),
            ),
          ])
        }),
      ),
    ],
  )
}

fn view_link(
  href: String,
  current: String,
  class: String,
  label: String,
) -> Element(Nil) {
  html.a(
    [
      attribute.href(href),
      case href == current {
        True -> attribute.aria_current("page")
        False -> attribute.none()
      },
      attribute.class("block rounded-md " <> class),
    ],
    [html.text(label)],
  )
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
          attribute.class("h-9 rounded-md bg-control px-3"),
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
        attribute.class("h-9 rounded-md bg-control px-2"),
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
