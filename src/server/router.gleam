import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import pages/index
import pages/l/id as short_link
import pages/links
import pages/links/id as link_page
import pages/links/id/delete
import pages/links/id/edit
import pages/links/new
import pages/not_found
import pages/robots
import pages/uuid
import pages/uuid/source as uuid_source
import server/context.{type Context}
import server/middleware

pub fn route(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use req <- middleware.apply(req)

  case request.path_segments(req) {
    [] -> index.handle(req, context)
    ["l", id] -> short_link.handle(req, context, id)
    ["links"] -> links.handle(req, context)
    ["links", "new"] -> new.handle(req, context)
    ["links", id] -> link_page.handle(req, context, id)
    ["links", id, "edit"] -> edit.handle(req, context, id)
    ["links", id, "delete"] -> delete.handle(req, context, id)
    ["robots.txt"] -> robots.handle(req, context)
    ["uuid"] -> uuid.handle(req, context)
    ["uuid", "source"] -> uuid_source.handle(req, context)
    _ -> not_found.handle(req, context)
  }
}
