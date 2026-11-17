import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/string
import hinoto/body.{type JsTypedArray}
import lustre/element.{type Element}

pub const font = "Noto Sans JP"

const width = 1200

const height = 630

const scale = 2

pub fn render(element: Element(Nil)) -> Promise(Result(JsTypedArray, Nil)) {
  do_render(
    element.to_string(element),
    width * scale,
    height * scale,
    scale,
    font,
  )
  |> promise.map(Ok)
  |> promise.rescue(fn(error) {
    io.println_error("og image: " <> string.inspect(error))
    Error(Nil)
  })
}

@external(javascript, "./og_image.ffi.ts", "render")
fn do_render(
  html: String,
  width: Int,
  height: Int,
  device_pixel_ratio: Int,
  font: String,
) -> Promise(JsTypedArray)
