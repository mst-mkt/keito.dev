import argv
import bigi.{type BigInt}
import glance.{type Expression, type Field, type Span, type Statement}
import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/javascript/array.{type Array}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/string

const stylesheet_directory = "entry"

const stylesheet = "style.css"

const source_directory = "src"

const class_functions = ["class", "cn"]

type Literal {
  Literal(location: Span, value: String)
}

type DesignSystem

type LoadOptions {
  LoadOptions(base: String)
}

@external(javascript, "@tailwindcss/node", "__unstable__loadDesignSystem")
fn load_design_system(
  css: String,
  options: LoadOptions,
) -> Promise(DesignSystem)

@external(javascript, "./sort_classes.ffi.ts", "get_class_order")
fn get_class_order(design: DesignSystem, classes: Array(String)) -> Dynamic

type ReadDirectoryOptions {
  ReadDirectoryOptions(recursive: Bool)
}

@external(javascript, "node:fs", "readdirSync")
fn read_directory(path: String, options: ReadDirectoryOptions) -> Array(String)

@external(javascript, "node:fs", "readFileSync")
fn read_file(path: String, encoding: String) -> String

@external(javascript, "node:fs", "writeFileSync")
fn write_file(path: String, data: String) -> Nil

@external(javascript, "node:process", "cwd")
fn cwd() -> String

@external(javascript, "node:process", "exit")
fn exit(code: Int) -> Nil

pub fn main() -> Promise(Nil) {
  let #(flags, files) =
    list.partition(argv.load().arguments, string.starts_with(_, "--"))
  let check = list.contains(flags, "--check")
  let files = case files {
    [] -> source_files()
    _ -> list.filter(files, string.ends_with(_, ".gleam"))
  }
  let css = read_file(stylesheet_directory <> "/" <> stylesheet, "utf8")
  let base = cwd() <> "/" <> stylesheet_directory
  use design <- promise.map(load_design_system(css, LoadOptions(base:)))
  let unsorted = list.filter(files, sort_file(_, design, check))

  case check, unsorted {
    True, [_, ..] -> {
      io.println_error("Unsorted Tailwind classes in:")
      list.each(unsorted, fn(file) { io.println_error("  " <> file) })
      exit(1)
    }
    _, _ -> Nil
  }
}

fn source_files() -> List(String) {
  read_directory(source_directory, ReadDirectoryOptions(recursive: True))
  |> array.to_list
  |> list.filter(string.ends_with(_, ".gleam"))
  |> list.sort(string.compare)
  |> list.map(fn(file) { source_directory <> "/" <> file })
}

fn sort_file(file: String, design: DesignSystem, check: Bool) -> Bool {
  let source = read_file(file, "utf8")
  case glance.module(source) {
    Error(_) -> {
      io.println_error("Skipped " <> file <> ": failed to parse")
      False
    }
    Ok(module) -> {
      let sorted =
        rewrite(source, class_literals(module), sort_classes(_, design))
      let changed = sorted != source
      case changed, check {
        True, False -> write_file(file, sorted)
        _, _ -> Nil
      }
      changed
    }
  }
}

fn sort_classes(value: String, design: DesignSystem) -> String {
  let classes =
    value
    |> string.replace("\n", " ")
    |> string.replace("\t", " ")
    |> string.split(" ")
    |> list.filter(fn(class) { class != "" })
    |> list.unique

  case classes {
    [] -> value
    _ -> {
      let leading =
        string.drop_end(value, string.length(string.trim_start(value)))
      let trailing =
        string.drop_start(value, string.length(string.trim_end(value)))
      let assert Ok(ranks) =
        get_class_order(design, array.from_list(classes))
        |> decode.run(decode.list(rank_decoder()))
      let sorted =
        ranks
        |> list.sort(fn(a, b) { compare_rank(a.1, b.1) })
        |> list.map(fn(rank) { rank.0 })
        |> string.join(" ")
      leading <> sorted <> trailing
    }
  }
}

fn rank_decoder() -> decode.Decoder(#(String, Option(BigInt))) {
  use class <- decode.field(0, decode.string)
  use rank <- decode.field(1, decode.optional(bigi.decoder()))
  decode.success(#(class, rank))
}

fn compare_rank(a: Option(BigInt), b: Option(BigInt)) -> Order {
  case a, b {
    None, None -> order.Eq
    None, Some(_) -> order.Lt
    Some(_), None -> order.Gt
    Some(a), Some(b) -> bigi.compare(a, b)
  }
}

fn rewrite(
  source: String,
  literals: List(Literal),
  sort: fn(String) -> String,
) -> String {
  let assert Ok(sorted) =
    literals
    |> list.filter(fn(literal) { !string.contains(literal.value, "\\") })
    |> list.sort(fn(a, b) { int.compare(b.location.start, a.location.start) })
    |> list.fold(bit_array.from_string(source), fn(bytes, literal) {
      let Literal(location:, value:) = literal
      let glance.Span(start:, end:) = byte_span(source, location)
      let assert Ok(before) = bit_array.slice(bytes, 0, start + 1)
      let assert Ok(after) =
        bit_array.slice(bytes, end - 1, bit_array.byte_size(bytes) - end + 1)
      bit_array.concat([before, bit_array.from_string(sort(value)), after])
    })
    |> bit_array.to_string
  sorted
}

fn byte_span(source: String, span: Span) -> Span {
  let glance.Span(start:, end:) = span
  let #(_, offset) =
    string.to_graphemes(source)
    |> list.fold_until(#(0, 0), fn(position, grapheme) {
      let #(units, bytes) = position
      case units < start {
        True ->
          list.Continue(#(
            units + bit_array.byte_size(<<grapheme:utf16>>) / 2,
            bytes + string.byte_size(grapheme),
          ))
        False -> list.Stop(position)
      }
    })
  glance.Span(start: offset, end: offset + end - start)
}

fn class_literals(module: glance.Module) -> List(Literal) {
  list.flat_map(module.functions, fn(function) {
    walk_statements(function.definition.body, False)
  })
}

fn is_class_function(function: Expression) -> Bool {
  case function {
    glance.Variable(name:, ..) | glance.FieldAccess(label: name, ..) ->
      list.contains(class_functions, name)
    _ -> False
  }
}

fn walk_statements(
  statements: List(Statement),
  in_class: Bool,
) -> List(Literal) {
  list.flat_map(statements, fn(statement) {
    case statement {
      glance.Use(function:, ..) -> walk_expression(function, False)
      glance.Assignment(value:, ..) -> walk_expression(value, False)
      glance.Assert(expression:, message:, ..) ->
        list.append(
          walk_expression(expression, False),
          walk_option(message, False),
        )
      glance.Expression(expression) -> walk_expression(expression, in_class)
    }
  })
}

fn walk_expression(expression: Expression, in_class: Bool) -> List(Literal) {
  case expression {
    glance.String(location:, value:) if in_class -> [Literal(location:, value:)]
    glance.Int(..)
    | glance.Float(..)
    | glance.String(..)
    | glance.Variable(..) -> []
    glance.NegateInt(value:, ..) | glance.NegateBool(value:, ..) ->
      walk_expression(value, in_class)
    glance.Block(statements:, ..) -> walk_statements(statements, in_class)
    glance.Panic(message:, ..) | glance.Todo(message:, ..) ->
      walk_option(message, False)
    glance.Tuple(elements:, ..) ->
      list.flat_map(elements, walk_expression(_, in_class))
    glance.List(elements:, rest:, ..) ->
      list.append(
        list.flat_map(elements, walk_expression(_, in_class)),
        walk_option(rest, in_class),
      )
    glance.Fn(body:, ..) -> walk_statements(body, False)
    glance.RecordUpdate(record:, fields:, ..) ->
      list.append(
        walk_expression(record, False),
        list.flat_map(fields, fn(field) { walk_option(field.item, False) }),
      )
    glance.FieldAccess(container:, ..) -> walk_expression(container, False)
    glance.Call(function:, arguments:, ..) ->
      list.append(
        walk_expression(function, False),
        walk_fields(arguments, is_class_function(function)),
      )
    glance.TupleIndex(tuple:, ..) -> walk_expression(tuple, False)
    glance.FnCapture(function:, arguments_before:, arguments_after:, ..) -> {
      let in_call = is_class_function(function)
      list.flatten([
        walk_expression(function, False),
        walk_fields(arguments_before, in_call),
        walk_fields(arguments_after, in_call),
      ])
    }
    glance.BitString(segments:, ..) ->
      list.flat_map(segments, fn(segment) { walk_expression(segment.0, False) })
    glance.Case(subjects:, clauses:, ..) ->
      list.append(
        list.flat_map(subjects, walk_expression(_, False)),
        list.flat_map(clauses, fn(clause) {
          list.append(
            walk_option(clause.guard, False),
            walk_expression(clause.body, in_class),
          )
        }),
      )
    glance.BinaryOperator(left:, right:, ..) ->
      list.append(
        walk_expression(left, in_class),
        walk_expression(right, in_class),
      )
    glance.Echo(expression:, message:, ..) ->
      list.append(
        walk_option(expression, in_class),
        walk_option(message, False),
      )
  }
}

fn walk_fields(
  fields: List(Field(Expression)),
  in_class: Bool,
) -> List(Literal) {
  list.flat_map(fields, fn(field) {
    case field {
      glance.LabelledField(item:, ..) | glance.UnlabelledField(item:) ->
        walk_expression(item, in_class)
      glance.ShorthandField(..) -> []
    }
  })
}

fn walk_option(
  expression: Option(Expression),
  in_class: Bool,
) -> List(Literal) {
  case expression {
    Some(expression) -> walk_expression(expression, in_class)
    None -> []
  }
}
