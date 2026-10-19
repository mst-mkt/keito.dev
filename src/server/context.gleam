import server/env.{type Env}

pub type Context {
  Context(env: Env, client_entry: String)
}
