import gleam/list
import gleam/option.{None, Some}
import lib/story.{Bool, Canvas, Docs, Number, Select, Show, Text}
import lustre/element

fn modules() -> List(story.Module) {
  [
    #("components/button", [
      story.new("primary", story.render(element.none())),
      story.new("ghost", story.render(element.none())),
    ]),
  ]
}

fn controls_story() -> story.Story {
  story.new("controls", {
    use _ <- story.text("label", "Button")
    use _ <- story.bool("disabled", True)
    use _ <- story.select("variant", 2, [#("primary", 1), #("ghost", 2)])

    story.render(element.none())
  })
}

fn values_story() -> story.Story {
  story.new("values", {
    use _ <- story.optional(
      "description",
      Some("Formatter"),
      otherwise: "",
      control: story.text,
    )
    use _ <- story.optional("rank", None, otherwise: 1, control: story.number)
    use _ <- story.number("stars", 128)

    story.render(element.none())
  })
}

pub fn resolve_docs_test() {
  let segments = ["components", "button"]

  let result = story.resolve(modules(), segments)

  let assert Ok(Docs(module:, stories:)) = result
  assert module == "components/button"
  assert list.map(stories, story.name) == ["primary", "ghost"]
}

pub fn resolve_show_test() {
  let segments = ["components", "button", "ghost"]

  let result = story.resolve(modules(), segments)

  let assert Ok(Show(module:, story: found)) = result
  assert module == "components/button"
  assert story.name(found) == "ghost"
}

pub fn resolve_canvas_test() {
  let segments = ["components", "button", "ghost", "canvas"]

  let result = story.resolve(modules(), segments)

  let assert Ok(Canvas(story: found)) = result
  assert story.name(found) == "ghost"
}

pub fn resolve_unknown_story_test() {
  let segments = ["components", "button", "danger"]

  let result = story.resolve(modules(), segments)

  assert result == Error(Nil)
}

pub fn run_defaults_test() {
  let query = []

  let #(_, controls) = story.run(controls_story(), query)

  assert controls
    == [
      Text(name: "label", value: "Button"),
      Bool(name: "disabled", value: True),
      Select(name: "variant", value: "ghost", options: ["primary", "ghost"]),
    ]
}

pub fn run_query_values_test() {
  let query = [#("label", "Submit"), #("variant", "primary")]

  let #(_, controls) = story.run(controls_story(), query)

  assert list.contains(controls, Text(name: "label", value: "Submit"))
  assert list.contains(
    controls,
    Select(name: "variant", value: "primary", options: ["primary", "ghost"]),
  )
}

pub fn run_checked_checkbox_test() {
  let query = [#("disabled", "false"), #("disabled", "true")]

  let #(_, controls) = story.run(controls_story(), query)

  assert list.contains(controls, Bool(name: "disabled", value: True))
}

pub fn run_unchecked_checkbox_test() {
  let query = [#("disabled", "false")]

  let #(_, controls) = story.run(controls_story(), query)

  assert list.contains(controls, Bool(name: "disabled", value: False))
}

pub fn run_unknown_select_option_test() {
  let query = [#("variant", "danger")]

  let #(_, controls) = story.run(controls_story(), query)

  assert list.contains(
    controls,
    Select(name: "variant", value: "ghost", options: ["primary", "ghost"]),
  )
}

pub fn run_present_optional_test() {
  let query = []

  let #(_, controls) = story.run(values_story(), query)

  assert list.contains(controls, Bool(name: "description", value: True))
  assert list.contains(
    controls,
    Text(name: "description_value", value: "Formatter"),
  )
}

pub fn run_absent_optional_test() {
  let query = []

  let #(_, controls) = story.run(values_story(), query)

  assert list.contains(controls, Bool(name: "rank", value: False))
  assert list.contains(controls, Number(name: "rank_value", value: 1))
}

pub fn run_unchecked_optional_test() {
  let query = [#("description", "false")]

  let #(_, controls) = story.run(values_story(), query)

  assert list.contains(controls, Bool(name: "description", value: False))
}

pub fn run_number_default_test() {
  let query = []

  let #(_, controls) = story.run(values_story(), query)

  assert list.contains(controls, Number(name: "stars", value: 128))
}

pub fn run_number_query_test() {
  let query = [#("stars", "52300")]

  let #(_, controls) = story.run(values_story(), query)

  assert list.contains(controls, Number(name: "stars", value: 52_300))
}

pub fn run_invalid_number_test() {
  let query = [#("stars", "many")]

  let #(_, controls) = story.run(values_story(), query)

  assert list.contains(controls, Number(name: "stars", value: 128))
}
