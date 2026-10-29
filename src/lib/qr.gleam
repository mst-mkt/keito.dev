import gleam/int
import gleam/list
import gleam/string
import glqr

pub fn modules(text: String) -> Result(List(List(Bool)), Nil) {
  let generated =
    glqr.new(text)
    |> glqr.error_correction(glqr.M)
    |> glqr.generate

  case generated {
    Ok(qr) -> {
      let #(size, bits) = glqr.to_bits(qr)
      Ok(list.sized_chunk(to_bools(bits, []), size))
    }
    Error(_) -> Error(Nil)
  }
}

pub fn path(modules: List(List(Bool))) -> String {
  modules
  |> list.index_map(fn(row, y) {
    list.index_map(row, fn(dark, x) {
      case dark {
        True -> "M" <> int.to_string(x) <> " " <> int.to_string(y) <> "h1v1h-1z"
        False -> ""
      }
    })
  })
  |> list.flatten
  |> string.concat
}

pub fn blocks(modules: List(List(Bool))) -> List(String) {
  modules
  |> list.sized_chunk(2)
  |> list.map(fn(rows) {
    case rows {
      [top, bottom] -> list.map2(top, bottom, block)
      [top] -> list.map(top, block(_, False))
      _ -> []
    }
    |> string.concat
  })
}

fn block(top: Bool, bottom: Bool) -> String {
  case top, bottom {
    True, True -> "█"
    True, False -> "▀"
    False, True -> "▄"
    False, False -> " "
  }
}

fn to_bools(bits: BitArray, acc: List(Bool)) -> List(Bool) {
  case bits {
    <<1:1, rest:bits>> -> to_bools(rest, [True, ..acc])
    <<0:1, rest:bits>> -> to_bools(rest, [False, ..acc])
    _ -> list.reverse(acc)
  }
}
