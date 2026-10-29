import gleam/list
import lib/qr

pub fn modules_square_test() {
  let text = "https://keito.dev/l/example"

  let assert Ok(modules) = qr.modules(text)

  let size = list.length(modules)
  assert list.all(modules, fn(row) { list.length(row) == size })
}

pub fn blocks_test() {
  let modules = [
    [True, True, False, False],
    [True, False, True, False],
    [True, False, False, True],
  ]

  let result = qr.blocks(modules)

  assert result == ["█▀▄ ", "▀  ▀"]
}

pub fn path_dark_modules_test() {
  let modules = [[True, False], [False, True]]

  let result = qr.path(modules)

  assert result == "M0 0h1v1h-1zM1 1h1v1h-1z"
}
