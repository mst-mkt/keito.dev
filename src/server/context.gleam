import bindings/env.{type Env}
import hinoto/runtime/workers.{type WorkersContext}

pub type Context {
  Context(env: Env, ctx: WorkersContext, client_entry: String)
}
