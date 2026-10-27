import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import lustre/element.{type Element}

pub opaque type Story {
  Story(name: String, args: Args(Element(Nil)))
}

pub opaque type Args(a) {
  Args(run: fn(Dict(String, String)) -> #(a, List(Control)))
}

pub type Control {
  Text(name: String, value: String)
  Bool(name: String, value: Bool)
  Select(name: String, value: String, options: List(String))
}

pub type Module =
  #(String, List(Story))

pub type Route {
  Docs(module: String, stories: List(Story))
  Show(module: String, story: Story)
  Canvas(story: Story)
}

pub fn new(name: String, args: Args(Element(msg))) -> Story {
  Story(name:, args: map(args, element.map(_, fn(_) { Nil })))
}

pub fn render(value: a) -> Args(a) {
  Args(fn(_) { #(value, []) })
}

pub fn text(
  name: String,
  default: String,
  next: fn(String) -> Args(a),
) -> Args(a) {
  use query <- control(next)
  let value = dict.get(query, name) |> result.unwrap(default)

  #(value, Text(name:, value:))
}

pub fn bool(name: String, default: Bool, next: fn(Bool) -> Args(a)) -> Args(a) {
  use query <- control(next)
  let value = case dict.get(query, name) {
    Ok(value) -> value == "true"
    Error(Nil) -> default
  }

  #(value, Bool(name:, value:))
}

pub fn select(
  name: String,
  default: value,
  options: List(#(String, value)),
  next: fn(value) -> Args(a),
) -> Args(a) {
  use query <- control(next)
  let selected =
    dict.get(query, name)
    |> result.try(fn(label) {
      list.find(options, fn(option) { option.0 == label })
    })
    |> result.lazy_or(fn() {
      list.find(options, fn(option) { option.1 == default })
    })
  let #(label, value) = result.unwrap(selected, #("", default))
  let labels = list.map(options, fn(option) { option.0 })

  #(value, Select(name:, value: label, options: labels))
}

pub fn name(story: Story) -> String {
  story.name
}

pub fn run(
  story: Story,
  query: List(#(String, String)),
) -> #(Element(Nil), List(Control)) {
  story.args.run(dict.from_list(query))
}

pub fn resolve(
  modules: List(Module),
  segments: List(String),
) -> Result(Route, Nil) {
  let module = string.join(segments, "/")

  case list.key_find(modules, module), list.reverse(segments) {
    Ok(stories), _ -> Ok(Docs(module:, stories:))
    Error(_), ["canvas", story_name, ..rest] ->
      find(modules, list.reverse(rest), story_name)
      |> result.map(fn(found) { Canvas(story: found.1) })
    Error(_), [story_name, ..rest] ->
      find(modules, list.reverse(rest), story_name)
      |> result.map(fn(found) { Show(module: found.0, story: found.1) })
    Error(_), [] -> Error(Nil)
  }
}

pub fn docs_path(module: String) -> String {
  "/story/" <> module
}

pub fn path(module: String, story: Story) -> String {
  docs_path(module) <> "/" <> story.name
}

fn find(
  modules: List(Module),
  segments: List(String),
  story_name: String,
) -> Result(#(String, Story), Nil) {
  let module = string.join(segments, "/")
  use stories <- result.try(list.key_find(modules, module))
  use story <- result.map(
    list.find(stories, fn(story) { story.name == story_name }),
  )

  #(module, story)
}

fn control(
  next: fn(value) -> Args(a),
  read: fn(Dict(String, String)) -> #(value, Control),
) -> Args(a) {
  use query <- Args
  let #(value, control) = read(query)
  let #(result, controls) = next(value).run(query)

  #(result, [control, ..controls])
}

fn map(args: Args(a), f: fn(a) -> b) -> Args(b) {
  use query <- Args
  let #(value, controls) = args.run(query)

  #(f(value), controls)
}
