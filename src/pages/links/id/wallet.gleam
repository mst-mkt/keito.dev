import bindings/env
import features/links/store
import features/links/wallet
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/string
import hinoto/body.{type Body}
import pages/not_found
import plinth/javascript/console
import server/context.{type Context}
import server/middleware
import server/respond

pub fn handle(
  req: Request(Body),
  context: Context,
  id: String,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use found <- promise.await(store.get(context.env, id))

  case found {
    Ok(current) -> {
      use signed <- promise.map(wallet.save_url(
        issuer_id: env.google_wallet_issuer_id(context.env),
        service_account: env.google_wallet_service_account(context.env),
        private_key: env.google_wallet_private_key(context.env),
        link: current,
      ))

      case signed {
        Ok(url) ->
          respond.redirect(302, url)
          |> response.set_header("cache-control", "no-store")
        Error(error) -> {
          console.error(
            "Google Wallet: " <> current.id <> ": " <> string.inspect(error),
          )
          respond.text(500, "Failed to create a Google Wallet pass.")
        }
      }
    }
    Error(_) -> not_found.handle(req, context)
  }
}
