import gleam/dict.{type Dict}
import gleam/list
import gleam/result
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
  let selected = case dict.get(query, name) {
    Ok(label) -> list.find(options, fn(option) { option.0 == label })
    Error(Nil) -> list.find(options, fn(option) { option.1 == default })
  }
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
