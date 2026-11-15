import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/string
import hinoto/body.{type Body}
import pages/blog
import pages/blog/atom
import pages/blog/slug as post_page
import pages/blog/source
import pages/index
import pages/l/id as short_link
import pages/links
import pages/links/id as link_page
import pages/links/id/delete
import pages/links/id/edit
import pages/links/id/wallet
import pages/links/new
import pages/not_found
import pages/robots
import pages/sitemap
import pages/uuid
import pages/uuid/source as uuid_source
import pages/yarn
import server/context.{type Context}
import server/middleware

pub fn route(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use req <- middleware.apply(req)

  case request.path_segments(req) {
    [] -> index.handle(req, context)
    ["blog"] -> blog.handle(req, context)
    ["blog", "atom.xml"] -> atom.handle(req, context)
    ["blog", slug] ->
      case string.ends_with(slug, ".md") {
        True -> source.handle(req, context, string.drop_end(slug, 3))
        False -> post_page.handle(req, context, slug)
      }
    ["l", id] -> short_link.handle(req, context, id)
    ["links"] -> links.handle(req, context)
    ["links", "new"] -> new.handle(req, context)
    ["links", id] -> link_page.handle(req, context, id)
    ["links", id, "edit"] -> edit.handle(req, context, id)
    ["links", id, "delete"] -> delete.handle(req, context, id)
    ["links", id, "wallet"] -> wallet.handle(req, context, id)
    ["robots.txt"] -> robots.handle(req, context)
    ["sitemap.xml"] -> sitemap.handle(req, context)
    ["uuid"] -> uuid.handle(req, context)
    ["uuid", "source"] -> uuid_source.handle(req, context)
    ["yarn"] -> yarn.handle(req, context)
    _ -> not_found.handle(req, context)
  }
}
