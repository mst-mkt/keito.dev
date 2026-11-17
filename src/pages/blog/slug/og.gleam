import features/blog/og_card.{type OgCard, OgCard}
import features/blog/post
import features/blog/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option
import gleam/result
import hinoto/body.{type Body, type JsTypedArray}
import layouts/base
import lib/cache
import lib/duration
import lib/og_image
import lib/workers_context
import pages/not_found
import server/context.{type Context}
import server/middleware
import server/respond

const cache_name = "og-image"

pub fn handle(
  req: Request(Body),
  context: Context,
  slug: String,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use found <- promise.await(store.get(context, slug))

  case found {
    Ok(entry) -> {
      let card = og_card.from_post(entry)
      let cache_key =
        base.origin <> post.og_image_path(slug) <> "?" <> og_card.to_query(card)
      use png <- promise.map(render_cached(context, cache_key, card))

      respond_png(png)
      |> response.set_header("cache-control", "public, max-age=86400")
    }
    Error(Nil) -> not_found.handle(req, context)
  }
}

pub fn preview(req: Request(Body)) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  let query = request.get_query(req) |> result.unwrap([])
  let param = fn(name) { list.key_find(query, name) }
  let card =
    OgCard(
      title: param("title") |> result.unwrap(""),
      emoji: param("emoji") |> result.unwrap(""),
      description: param("description") |> option.from_result,
    )

  og_image.render(og_card.view(card)) |> promise.map(respond_png)
}

fn render_cached(
  context: Context,
  cache_key: String,
  card: OgCard,
) -> Promise(Result(JsTypedArray, Nil)) {
  use cached <- promise.await(
    cache.get(cache_name, cache_key) |> promise.rescue(fn(_) { Error(Nil) }),
  )

  case cached {
    Ok(png) -> promise.resolve(Ok(png))
    Error(Nil) -> {
      use rendered <- promise.map(og_image.render(og_card.view(card)))

      case rendered {
        Ok(png) ->
          cache.put(cache_name, cache_key, png, "image/png", duration.days(30))
          |> workers_context.wait_until(context.ctx, _)
        Error(Nil) -> Nil
      }
      rendered
    }
  }
}

fn respond_png(png: Result(JsTypedArray, Nil)) -> Response(Body) {
  case png {
    Ok(png) -> respond.png(200, png)
    Error(Nil) -> respond.text(503, "Service Unavailable")
  }
}
