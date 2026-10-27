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

fn to_bools(bits: BitArray, acc: List(Bool)) -> List(Bool) {
  case bits {
    <<1:1, rest:bits>> -> to_bools(rest, [True, ..acc])
    <<0:1, rest:bits>> -> to_bools(rest, [False, ..acc])
    _ -> list.reverse(acc)
  }
}
