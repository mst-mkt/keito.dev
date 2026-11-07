import gleam/javascript/promise.{type Promise}
import hinoto/runtime/workers.{type WorkersContext}

@external(javascript, "./workers_context.ffi.ts", "waitUntil")
pub fn wait_until(ctx: WorkersContext, task: Promise(a)) -> Nil
