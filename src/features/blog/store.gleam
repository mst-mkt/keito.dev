import bindings/env
import bindings/kv
import bindings/service
import features/blog/embed
import features/blog/markdown
import features/blog/post.{type Post}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/http/response.{type Response, Response}
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import lib/duration
import lib/workers_context
import lustre/element
import server/context.{type Context}

pub fn list(context: Context) -> Promise(Result(List(Post), Nil)) {
  use index <- promise.map(fetch_file(context, "/index.json"))
  use index <- result.try(index)

  json.parse(index.body, decode.list(post.decoder()))
  |> result.replace_error(Nil)
}

pub fn get(context: Context, slug: String) -> Promise(Result(Post, Nil)) {
  use posts <- promise.map(list(context))
  use posts <- result.try(posts)

  list.find(posts, fn(post) { post.slug == slug })
}

pub fn source(context: Context, slug: String) -> Promise(Result(String, Nil)) {
  use found <- promise.map(fetch_file(context, source_path(slug)))

  result.map(found, fn(found) { found.body })
}

pub fn content(context: Context, slug: String) -> Promise(Result(String, Nil)) {
  use found <- promise.try_await(fetch_file(context, source_path(slug)))
  let content = case response.get_header(found, "etag") {
    Ok(etag) ->
      render_cached(context, "post:" <> slug <> ":" <> etag, found.body)
    Error(Nil) -> render(context, found.body) |> promise.map(unwrap)
  }

  promise.map(content, Ok)
}

fn render_cached(
  context: Context,
  key: String,
  source: String,
) -> Promise(String) {
  let namespace = env.post_cache(context.env)
  use cached <- promise.await(
    kv.get(namespace, key) |> promise.rescue(fn(_) { Error(Nil) }),
  )

  case cached {
    Ok(#(content, _)) -> promise.resolve(content)
    Error(Nil) -> {
      use rendered <- promise.map(render(context, source))

      case rendered {
        Ok(content) ->
          kv.put(namespace, key, content, [], ttl: Some(duration.days(1)))
          |> workers_context.wait_until(context.ctx, _)
        Error(_) -> Nil
      }

      unwrap(rendered)
    }
  }
}

fn render(context: Context, source: String) -> Promise(Result(String, String)) {
  let embeds = markdown.embeds(source)
  use viewed <- promise.await(
    list.map(embeds, embed.try_view(context, _)) |> promise.await_list,
  )
  let views = list.zip(embeds, list.map(viewed, unwrap))
  let embed_view = fn(embedded) {
    case list.key_find(views, embedded) {
      Ok(view) -> promise.resolve(view)
      Error(Nil) -> embed.view(context, embedded)
    }
  }
  use elements <- promise.map(markdown.render(source, embed_view))
  let content = list.map(elements, element.to_string) |> string.concat

  case list.all(viewed, result.is_ok) {
    True -> Ok(content)
    False -> Error(content)
  }
}

fn unwrap(result: Result(a, a)) -> a {
  case result {
    Ok(value) | Error(value) -> value
  }
}

fn source_path(slug: String) -> String {
  "/" <> slug <> ".md"
}

fn fetch_file(
  context: Context,
  path: String,
) -> Promise(Result(Response(String), Nil)) {
  let req = request.new() |> request.set_host("posts") |> request.set_path(path)
  let sent =
    service.fetch(env.posts(context.env), fetch.to_fetch_request(req))
    |> promise.map(Ok)
    |> promise.rescue(fn(_) { Error(Nil) })
  use sent <- promise.try_await(sent)

  case fetch.from_fetch_response(sent) {
    Response(status: 200, ..) as found ->
      fetch.read_text_body(found)
      |> promise.map(result.replace_error(_, Nil))
    _ -> promise.resolve(Error(Nil))
  }
}
