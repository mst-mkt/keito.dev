import gleam/fetch.{type FetchBody}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/javascript/promise.{type Promise}

pub type Fetched {
  Found(String)
  Gone
  Failed
}

pub type Reader =
  fn(Response(FetchBody)) -> Promise(Result(String, Nil))

pub fn get(url: String, read: Reader) -> Promise(Fetched) {
  case request.to(url) {
    Ok(req) -> send(req, read)
    Error(Nil) -> promise.resolve(Failed)
  }
}

pub fn send(req: Request(String), read: Reader) -> Promise(Fetched) {
  use sent <- promise.await(fetch.send(req))

  case sent {
    Ok(Response(status: 404, ..)) | Ok(Response(status: 410, ..)) ->
      promise.resolve(Gone)
    Ok(response) if response.status >= 200 && response.status < 300 -> {
      use body <- promise.map(read(response))

      case body {
        Ok(body) -> Found(body)
        Error(Nil) -> Failed
      }
    }
    _ -> promise.resolve(Failed)
  }
}

pub fn read_text(
  response: Response(FetchBody),
) -> Promise(Result(String, Nil)) {
  use read <- promise.map(fetch.read_text_body(response))

  case read {
    Ok(Response(body:, ..)) -> Ok(body)
    Error(_) -> Error(Nil)
  }
}
