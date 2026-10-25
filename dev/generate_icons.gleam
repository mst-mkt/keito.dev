import argv
import gleam/bool
import gleam/io
import gleam/javascript/array.{type Array}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/pair
import gleam/result
import gleam/string

const output = "src/components/icons.gleam"

const iconoir_directory = "node_modules/iconoir/icons/regular"

const iconoir_license = "node_modules/iconoir/LICENSE"

const iconoir_section = "Iconoir"

const iconoir_url = "https://iconoir.com/"

const usage =
  "Usage:
  gleam run -m generate_icons -- add <name>...
  gleam run -m generate_icons -- add <name> <file.svg> [<options>]
  gleam run -m generate_icons -- update [--check]

Options:
  --section <id>         Put the icon under the `// ## <id>` section
  --source <url>         Where the icons of the section come from
  --license <name>       License of the section, such as MIT
  --license-body <file>  License text, required for MIT, ISC, BSD-* and Apache-2.0
  --terms <url>          Terms of use of the section"

const options = [
  "--section", "--source", "--license", "--license-body", "--terms",
]

const defaults = [
  #("fill", "none"),
  #("stroke", "currentColor"),
  #("stroke-width", "1.5"),
  #("stroke-linecap", "round"),
  #("stroke-linejoin", "round"),
]

const initials = [
  #("fill", "black"),
  #("stroke", "none"),
  #("stroke-width", "1"),
  #("stroke-linecap", "butt"),
  #("stroke-linejoin", "miter"),
]

const root_attributes = [
  "width", "height", "viewBox", "xmlns", "xmlns:xlink", "version", "class", "id",
  "role",
]

const leaf_elements = [
  "path", "circle", "ellipse", "line", "polygon", "polyline", "rect",
]

const shape_elements = ["use", ..leaf_elements]

const container_elements = [
  #("g", "g"),
  #("defs", "defs"),
  #("mask", "mask"),
  #("clipPath", "clip_path"),
]

const ignored_elements = ["title", "desc"]

const imports = [
  "import lustre/attribute.{type Attribute}",
  "import lustre/element.{type Element}", "import lustre/element/html",
  "import lustre/element/svg",
]

const reserved_names = [
  "as", "assert", "auto", "case", "const", "delegate", "derive", "echo", "else",
  "fn", "if", "implement", "import", "let", "macro", "opaque", "panic", "pub",
  "test", "todo", "type", "use", "icon",
]

type Attributes =
  List(#(String, String))

type Node {
  Node(tag: String, attributes: Attributes, children: List(Node))
}

type Section {
  Section(id: Option(String), credit: Credit, icons: List(#(String, String)))
}

type Credit {
  Credit(
    source: Option(String),
    license: Option(String),
    license_body: Option(String),
    terms: Option(String),
  )
}

const no_credit =
  Credit(source: None, license: None, license_body: None, terms: None)

type ExecOptions {
  ExecOptions(input: String, encoding: String)
}

@external(javascript, "node:fs", "existsSync")
fn exists(path: String) -> Bool

@external(javascript, "node:fs", "readFileSync")
fn read_file(path: String, encoding: String) -> String

@external(javascript, "node:fs", "writeFileSync")
fn write_file(path: String, data: String) -> Nil

@external(javascript, "node:child_process", "execFileSync")
fn exec_file(
  file: String,
  arguments: Array(String),
  options: ExecOptions,
) -> String

@external(javascript, "node:process", "exit")
fn exit(code: Int) -> Nil

pub fn main() -> Nil {
  let result = case argv.load().arguments {
    ["add", name, file, ..rest] ->
      case string.ends_with(file, ".svg") {
        True -> add_custom(name, file, rest)
        False -> add_iconoir([name, file, ..rest])
      }
    ["add", name] -> add_iconoir([name])
    ["update"] -> update(False)
    ["update", "--check"] -> update(True)
    _ -> Error(usage)
  }

  case result {
    Ok(Nil) -> Nil
    Error(message) -> {
      io.println_error(message)
      exit(1)
    }
  }
}

fn add_iconoir(names: List(String)) -> Result(Nil, String) {
  use sections <- result.try(load())
  use sections <- result.try(
    list.try_fold(names, sections, fn(sections, name) {
      insert(sections, Some(iconoir_section), no_credit, to_function(name), "")
    }),
  )
  save(sections)
}

fn add_custom(
  name: String,
  file: String,
  arguments: List(String),
) -> Result(Nil, String) {
  use parsed <- result.try(parse_options(arguments, []))
  let given = fn(name) { option.from_result(list.key_find(parsed, name)) }
  let section = given("--section")
  use <- bool.guard(
    section == Some(iconoir_section),
    Error("The `// ## Iconoir` section is generated from Iconoir"),
  )
  use <- bool.guard(
    section == None && parsed != [],
    Error("Section options require --section"),
  )
  use sections <- result.try(load())
  let function = to_function(name)
  use <- bool.lazy_guard(has_icon(sections, function), fn() {
    io.println("Skipped " <> function <> ": already exists")
    Ok(Nil)
  })
  use license_body <- result.try(case given("--license-body") {
    Some(file) -> {
      use text <- result.try(read_existing(file, "File not found: " <> file))
      license_text(text)
      |> option.to_result("The license body " <> file <> " is empty")
      |> result.map(Some)
    }
    None -> Ok(None)
  })
  use svg <- result.try(read_existing(file, "File not found: " <> file))
  use source <- result.try(icon_source(function, svg))
  let credit =
    Credit(
      source: given("--source"),
      license: given("--license"),
      license_body:,
      terms: given("--terms"),
    )
  use sections <- result.try(insert(sections, section, credit, function, source))
  save(sections)
}

fn license_text(text: String) -> Option(String) {
  let text =
    string.split(text, "\n")
    |> list.map(string.trim_end)
    |> list.drop_while(string.is_empty)
    |> string.join("\n")
    |> string.trim_end
  case text {
    "" -> None
    _ -> Some(text)
  }
}

fn parse_options(
  arguments: List(String),
  parsed: List(#(String, String)),
) -> Result(List(#(String, String)), String) {
  case arguments {
    [] -> Ok(parsed)
    [option, ..rest] ->
      case list.contains(options, option), rest {
        False, _ -> Error("Unknown option: " <> option <> "\n\n" <> usage)
        True, [value, ..rest] -> {
          let value = string.trim(value)
          case
            value == ""
            || string.contains(value, "\n")
            || string.starts_with(value, "--")
          {
            True -> Error("Invalid value of " <> option)
            False -> parse_options(rest, list.key_set(parsed, option, value))
          }
        }
        True, [] -> Error("Missing value of " <> option)
      }
  }
}

fn update(check: Bool) -> Result(Nil, String) {
  use <- bool.guard(!exists(output), Ok(Nil))
  let current = read_file(output, "utf8")
  use sections <- result.try(parse_module(current))
  use source <- result.try(render(sections))

  case check, source == current {
    True, False ->
      Error(output <> " is out of date. Run `generate_icons update`.")
    True, True -> Ok(Nil)
    False, _ -> Ok(write_file(output, source))
  }
}

fn save(sections: List(Section)) -> Result(Nil, String) {
  use source <- result.map(render(sections))
  write_file(output, source)
}

fn read_existing(path: String, error: String) -> Result(String, String) {
  case exists(path) {
    True -> Ok(read_file(path, "utf8"))
    False -> Error(error)
  }
}

fn to_function(name: String) -> String {
  let function = string.replace(name, "-", "_")
  case list.contains(reserved_names, function) {
    True -> function <> "_"
    False -> function
  }
}

fn from_function(function: String) -> String {
  let base = string.drop_end(function, 1)
  let name = case
    string.ends_with(function, "_") && list.contains(reserved_names, base)
  {
    True -> base
    False -> function
  }
  string.replace(name, "_", "-")
}

fn insert(
  sections: List(Section),
  id: Option(String),
  credit: Credit,
  function: String,
  source: String,
) -> Result(List(Section), String) {
  use <- bool.guard(
    !valid_name(function),
    Error("Invalid function name: " <> function),
  )
  use <- bool.lazy_guard(has_icon(sections, function), fn() {
    io.println("Skipped " <> function <> ": already exists")
    Ok(sections)
  })

  let sections = case list.any(sections, fn(section) { section.id == id }) {
    True -> sections
    False -> [Section(id:, credit: no_credit, icons: []), ..sections]
  }
  Ok(
    list.map(sections, fn(section) {
      case section.id == id {
        True ->
          Section(
            ..section,
            credit: Credit(
              source: option.or(credit.source, section.credit.source),
              license: option.or(credit.license, section.credit.license),
              license_body: option.or(
                credit.license_body,
                section.credit.license_body,
              ),
              terms: option.or(credit.terms, section.credit.terms),
            ),
            icons: [#(function, source), ..section.icons],
          )
        False -> section
      }
    }),
  )
}

fn has_icon(sections: List(Section), function: String) -> Bool {
  list.any(sections, fn(section) {
    result.is_ok(list.key_find(section.icons, function))
  })
}

fn valid_name(name: String) -> Bool {
  let lower = "abcdefghijklmnopqrstuvwxyz"
  case string.to_graphemes(name) {
    [first, ..rest] ->
      string.contains(lower, first)
      && list.all(rest, string.contains(lower <> "0123456789_", _))
    [] -> False
  }
}

fn load() -> Result(List(Section), String) {
  case exists(output) {
    True -> parse_module(read_file(output, "utf8"))
    False -> Ok([Section(id: None, credit: no_credit, icons: [])])
  }
}

fn parse_module(source: String) -> Result(List(Section), String) {
  let #(header, rest) =
    string.split(source, "\n")
    |> list.split_while(fn(line) { !string.starts_with(line, "import ") })
  let #(between, rest) =
    list.split_while(rest, fn(line) { !string.starts_with(line, "fn icon(") })
  let body =
    rest
    |> list.drop_while(fn(line) { line != "}" })
    |> list.drop(1)

  let unknown_header =
    list.filter(header, fn(line) {
      line != "" && !string.starts_with(line, "////")
    })
  let unknown_imports =
    list.filter(between, fn(line) {
      line != "" && !list.contains(imports, line)
    })
  use <- bool.guard(
    unknown_header != [],
    Error(unexpected("lines before the imports", unknown_header)),
  )
  use <- bool.guard(
    unknown_imports != [],
    Error(unexpected(
      "lines between the imports and the icon helper",
      unknown_imports,
    )),
  )
  parse_body(body)
}

fn parse_body(lines: List(String)) -> Result(List(Section), String) {
  use #(current, done) <- result.try(
    lines
    |> list.chunk(string.is_empty)
    |> list.filter(fn(chunk) { !list.all(chunk, string.is_empty) })
    |> list.try_fold(
      #(Section(id: None, credit: no_credit, icons: []), []),
      parse_chunk,
    ),
  )
  let sections =
    list.reverse([current, ..done])
    |> list.map(fn(section) {
      Section(..section, icons: list.reverse(section.icons))
    })

  use Nil <- result.map(
    list.try_each(
      list.flat_map(sections, fn(section) { section.icons }),
      fn(icon) {
        let top_level =
          string.split(icon.1, "\n")
          |> list.filter(fn(line) {
            line != ""
            && !list.any([" ", ")", "}"], string.starts_with(line, _))
          })
        case top_level {
          [_] -> Ok(Nil)
          _ -> Error(unexpected("lines in " <> icon.0, top_level))
        }
      },
    ),
  )
  sections
}

fn parse_chunk(
  state: #(Section, List(Section)),
  chunk: List(String),
) -> Result(#(Section, List(Section)), String) {
  let #(section, done) = state

  case chunk, section.icons {
    ["// ## " <> id, ..comment], icons -> {
      let duplicate =
        list.any([section, ..done], fn(other) { other.id == Some(id) })
      case closed(icons), parse_credit(comment), duplicate {
        True, Ok(credit), False ->
          Ok(#(Section(id: Some(id), credit:, icons: []), [section, ..done]))
        _, _, _ -> Error(unexpected("section", chunk))
      }
    }
    ["pub fn " <> signature, ..], icons -> {
      use <- bool.guard(
        !closed(icons),
        Error(unexpected("lines after the icon helper", chunk)),
      )
      let function =
        string.split_once(signature, "(")
        |> result.map(pair.first)
        |> result.unwrap(signature)
      let icon = #(function, string.join(chunk, "\n"))
      Ok(#(Section(..section, icons: [icon, ..icons]), done))
    }
    _, [#(function, source), ..icons] -> {
      use <- bool.guard(
        closed(section.icons),
        Error(unexpected("lines after the icon helper", chunk)),
      )
      let icon = #(function, source <> "\n\n" <> string.join(chunk, "\n"))
      Ok(#(Section(..section, icons: [icon, ..icons]), done))
    }
    _, [] -> Error(unexpected("lines after the icon helper", chunk))
  }
}

fn parse_credit(lines: List(String)) -> Result(Credit, Nil) {
  let #(fields, body) = list.split_while(lines, fn(line) { line != "//" })
  use credit <- result.try(
    list.try_fold(fields, no_credit, fn(credit, line) {
      case line {
        "// Source: " <> value if credit.source == None ->
          Ok(Credit(..credit, source: Some(value)))
        "// License: " <> value if credit.license == None ->
          Ok(Credit(..credit, license: Some(value)))
        "// Terms: " <> value if credit.terms == None ->
          Ok(Credit(..credit, terms: Some(value)))
        _ -> Error(Nil)
      }
    }),
  )
  case body {
    [] -> Ok(credit)
    [_, ..text] -> {
      use text <- result.map(
        list.try_map(text, fn(line) {
          case line {
            "//" -> Ok("")
            "// " <> line -> Ok(line)
            _ -> Error(Nil)
          }
        }),
      )
      Credit(..credit, license_body: license_text(string.join(text, "\n")))
    }
  }
}

fn credit_lines(credit: Credit) -> List(String) {
  let fields =
    option.values([
      option.map(credit.source, string.append("Source: ", _)),
      option.map(credit.license, string.append("License: ", _)),
      option.map(credit.terms, string.append("Terms: ", _)),
    ])
  let body = case credit.license_body {
    Some(text) -> ["", ..string.split(text, "\n")]
    None -> []
  }
  list.append(fields, body)
  |> list.map(fn(line) { string.trim_end("// " <> line) })
}

fn requires_license_body(license: String) -> Bool {
  list.contains(["MIT", "ISC", "Apache-2.0"], license)
  || string.starts_with(license, "BSD-")
}

fn closed(icons: List(#(String, String))) -> Bool {
  case icons {
    [#(_, source), ..] -> string.ends_with(source, "\n}")
    [] -> True
  }
}

fn unexpected(context: String, lines: List(String)) -> String {
  "Unexpected "
  <> context
  <> " in "
  <> output
  <> ":\n"
  <> string.join(list.take(lines, 5), "\n")
}

fn render(sections: List(Section)) -> Result(String, String) {
  use <- bool.guard(
    list.all(sections, fn(section) { section.icons == [] }),
    Error("No icons left. Delete " <> output <> " instead."),
  )
  use sections <- result.try(
    sections
    |> list.filter(fn(section) {
      section.id != Some(iconoir_section) || section.icons != []
    })
    |> list.try_map(fn(section) {
      case section.id == Some(iconoir_section) {
        True -> iconoir(section)
        False -> Ok(section)
      }
    }),
  )
  use Nil <- result.try(
    list.try_each(sections, fn(section) {
      case section.id, section.credit {
        Some(id), Credit(license: Some(license), license_body: None, ..) ->
          case requires_license_body(license) {
            True ->
              Error(
                "`// ## " <> id <> "` needs the license body of " <> license,
              )
            False -> Ok(Nil)
          }
        _, _ -> Ok(Nil)
      }
    }),
  )

  let blocks =
    sections
    |> list.sort(fn(a, b) { compare_ids(a.id, b.id) })
    |> list.flat_map(fn(section) {
      let heading = case section.id {
        Some(id) -> [
          string.join(["// ## " <> id, ..credit_lines(section.credit)], "\n"),
        ]
        None -> []
      }
      section.icons
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
      |> list.map(pair.second)
      |> list.append(heading, _)
    })
  let source = string.join([header(), ..blocks], "\n\n") <> "\n"

  Ok(exec_file(
    "gleam",
    array.from_list(["format", "--stdin"]),
    ExecOptions(input: source, encoding: "utf8"),
  ))
}

fn compare_ids(a: Option(String), b: Option(String)) -> order.Order {
  case a, b {
    None, None -> order.Eq
    None, Some(_) -> order.Lt
    Some(_), None -> order.Gt
    Some(a), Some(b) -> string.compare(a, b)
  }
}

fn iconoir(section: Section) -> Result(Section, String) {
  use <- bool.guard(
    !exists(iconoir_directory),
    Error("Iconoir is not installed. Run `pnpm install`."),
  )
  let credit =
    Credit(
      source: Some(iconoir_url),
      license: Some("MIT"),
      license_body: license_text(read_file(iconoir_license, "utf8")),
      terms: None,
    )
  use icons <- result.map(
    list.try_map(section.icons, fn(icon) {
      let name = from_function(icon.0)
      use svg <- result.try(read_existing(
        iconoir_directory <> "/" <> name <> ".svg",
        "Iconoir has no icon named " <> name,
      ))
      use source <- result.map(icon_source(icon.0, svg))
      #(icon.0, source)
    }),
  )
  Section(..section, credit:, icons:)
}

fn header() -> String {
  let attributes =
    list.flatten([
      list.map([#("width", "1em"), #("height", "1em")], attribute_source),
      ["attribute.attribute(\"viewBox\", view_box)"],
      list.map(defaults, attribute_source),
      ["..attributes"],
    ])

  "//// Generated by `gleam run -m generate_icons`.
////
//// - `add <name>...` adds icons from Iconoir.
//// - `add <name> <file.svg>` adds a custom icon.
////   `--section <id>` puts it under the `// ## <id>` section.
////   `--source`, `--license`, `--license-body` and `--terms` record where the section comes from.
//// - `update` regenerates the `// ## Iconoir` section and keeps everything else as written.
////
//// Icons are grouped by where they come from.
//// Icons before the first section are original.
////
//// Size and style icons with classes such as `size-4`.
//// Attributes such as `width` or `stroke-width` are rendered twice instead of overriding the defaults.

" <> string.join(imports, "\n") <> "

fn icon(view_box: String, attributes: List(Attribute(msg)), children: List(Element(msg))) -> Element(msg) {
  html.svg(" <> list_source(attributes) <> ", children)
}"
}

fn icon_source(function: String, svg: String) -> Result(String, String) {
  use root <- result.try(parse_svg(svg))
  use #(view_box, children) <- result.try(normalize(root))
  use children <- result.map(list.try_map(children, element_source))
  "pub fn "
  <> function
  <> "(attributes: List(Attribute(msg))) -> Element(msg) {\n  icon("
  <> quote(view_box)
  <> ", attributes, "
  <> list_source(children)
  <> ")\n}"
}

fn normalize(root: Node) -> Result(#(String, List(Node)), String) {
  use <- bool.guard(root.tag != "svg", Error("The root element must be <svg>"))
  use view_box <- result.try(
    list.key_find(root.attributes, "viewBox")
    |> result.replace_error("The root <svg> must have a viewBox"),
  )
  use Nil <- result.try(reject_style(root))

  let unsupported =
    list.filter(root.attributes, fn(attribute) {
      !list.contains(root_attributes, attribute.0) && !has_default(attribute.0)
    })
  use <- bool.guard(
    unsupported != [],
    Error(
      "Unsupported attributes on <svg>: "
      <> string.join(list.map(unsupported, pair.first), ", "),
    ),
  )
  let context = inherit(initials, root)

  Ok(#(view_box, list.map(root.children, normalize_node(_, context))))
}

fn normalize_node(node: Node, context: Attributes) -> Node {
  use <- bool.guard(
    list.contains(
      ["symbol", "animate", "animateMotion", "animateTransform", "set"],
      node.tag,
    ),
    node,
  )
  let context = inherit(context, node)
  let own =
    list.filter(node.attributes, fn(attribute) { !has_default(attribute.0) })
  let overrides = case
    node.tag == "defs" || list.contains(shape_elements, node.tag)
  {
    True ->
      list.filter(context, fn(entry) {
        list.key_find(defaults, entry.0) != Ok(entry.1)
      })
    False -> []
  }
  let children = case node.tag {
    "defs" -> node.children
    _ -> list.map(node.children, normalize_node(_, context))
  }

  Node(..node, attributes: list.append(own, overrides), children:)
}

fn reject_style(node: Node) -> Result(Nil, String) {
  use <- bool.guard(
    result.is_ok(list.key_find(node.attributes, "style")),
    Error(
      "The style attribute on <"
      <> node.tag
      <> "> is not supported. Use presentation attributes instead.",
    ),
  )
  list.try_each(node.children, reject_style)
}

fn has_default(name: String) -> Bool {
  result.is_ok(list.key_find(defaults, name))
}

fn inherit(context: Attributes, node: Node) -> Attributes {
  list.map(context, fn(entry) {
    #(entry.0, result.unwrap(list.key_find(node.attributes, entry.0), entry.1))
  })
}

fn element_source(node: Node) -> Result(String, String) {
  let attributes = list_source(list.map(node.attributes, attribute_source))
  use children <- result.map(list.try_map(node.children, element_source))

  case
    list.contains(leaf_elements, node.tag),
    list.key_find(container_elements, node.tag),
    children
  {
    True, _, [] -> "svg." <> node.tag <> "(" <> attributes <> ")"
    _, Ok(function), _ ->
      "svg."
      <> function
      <> "("
      <> attributes
      <> ", "
      <> list_source(children)
      <> ")"
    _, _, _ ->
      "element.namespaced(\"http://www.w3.org/2000/svg\", "
      <> quote(node.tag)
      <> ", "
      <> attributes
      <> ", "
      <> list_source(children)
      <> ")"
  }
}

fn attribute_source(attribute: #(String, String)) -> String {
  "attribute.attribute("
  <> quote(attribute.0)
  <> ", "
  <> quote(attribute.1)
  <> ")"
}

fn list_source(items: List(String)) -> String {
  "[" <> string.join(items, ", ") <> "]"
}

fn quote(value: String) -> String {
  "\""
  <> value
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  <> "\""
}

fn parse_svg(source: String) -> Result(Node, String) {
  case parse_nodes(source, []) {
    Ok(#([root], "")) -> Ok(root)
    Ok(#(_, "")) -> Error("Expected a single root element")
    Ok(#(_, rest)) -> Error("Unexpected " <> string.slice(rest, 0, 20))
    Error(message) -> Error(message)
  }
}

fn parse_nodes(
  input: String,
  nodes: List(Node),
) -> Result(#(List(Node), String), String) {
  let #(text, rest) =
    string.split_once(input, "<") |> result.unwrap(#(input, ""))
  use <- bool.guard(
    string.trim(text) != "",
    Error("Text content such as <text> or <style> is not supported"),
  )

  case rest {
    "" -> Ok(#(list.reverse(nodes), ""))
    "/" <> _ -> Ok(#(list.reverse(nodes), "<" <> rest))
    "!--" <> rest -> {
      use rest <- result.try(skip_past(rest, "-->", "Unclosed comment"))
      parse_nodes(rest, nodes)
    }
    "![CDATA[" <> _ -> Error("CDATA is not supported")
    "?" <> rest | "!" <> rest -> {
      use rest <- result.try(skip_past(rest, ">", "Unclosed declaration"))
      parse_nodes(rest, nodes)
    }
    rest -> {
      use #(node, rest) <- result.try(parse_element(rest))
      case list.contains(ignored_elements, node.tag) {
        True -> parse_nodes(rest, nodes)
        False -> parse_nodes(rest, [node, ..nodes])
      }
    }
  }
}

fn skip_past(
  input: String,
  delimiter: String,
  error: String,
) -> Result(String, String) {
  string.split_once(input, delimiter)
  |> result.map(pair.second)
  |> result.replace_error(error)
}

fn parse_element(input: String) -> Result(#(Node, String), String) {
  use #(head, rest) <- result.try(
    string.split_once(input, ">") |> result.replace_error("Unclosed tag"),
  )
  let head =
    head
    |> string.replace("\n", " ")
    |> string.replace("\r", " ")
    |> string.replace("\t", " ")
    |> string.trim
  let #(head, self_closing) = case string.ends_with(head, "/") {
    True -> #(string.drop_end(head, 1), True)
    False -> #(head, False)
  }
  let #(tag, attributes) =
    string.split_once(head, " ") |> result.unwrap(#(head, ""))

  use attributes <- result.try(parse_attributes(attributes, []))
  use <- bool.guard(
    self_closing,
    Ok(#(Node(tag:, attributes:, children: []), rest)),
  )
  use <- bool.lazy_guard(list.contains(ignored_elements, tag), fn() {
    use rest <- result.map(skip_past(
      rest,
      "</" <> tag <> ">",
      "Unclosed <" <> tag <> ">",
    ))
    #(Node(tag:, attributes:, children: []), rest)
  })

  use #(children, rest) <- result.try(parse_nodes(rest, []))
  let closing = string.split_once(rest, ">")
  case result.map(closing, pair.map_first(_, string.trim_end)) {
    Ok(#("</" <> name, rest)) if name == tag ->
      Ok(#(Node(tag:, attributes:, children:), rest))
    _ -> Error("Unclosed <" <> tag <> ">")
  }
}

fn parse_attributes(
  input: String,
  attributes: Attributes,
) -> Result(Attributes, String) {
  case string.trim_start(input) {
    "" -> Ok(list.reverse(attributes))
    input -> {
      use #(name, rest) <- result.try(
        string.split_once(input, "=")
        |> result.replace_error("Invalid attribute: " <> input),
      )
      let name = string.trim_end(name)
      use <- bool.guard(
        name == "" || string.contains(name, " "),
        Error("Invalid attribute: " <> input),
      )
      use #(value, rest) <- result.try(
        case string.trim_start(rest) {
          "\"" <> rest -> string.split_once(rest, "\"")
          "'" <> rest -> string.split_once(rest, "'")
          _ -> Error(Nil)
        }
        |> result.replace_error("Invalid value of " <> name),
      )
      use <- bool.guard(
        string.contains(value, "&"),
        Error("Entities in the value of " <> name <> " are not supported"),
      )

      let name = case name {
        "xlink:href" -> "href"
        _ -> name
      }
      parse_attributes(rest, [#(name, value), ..attributes])
    }
  }
}
