import gleam/list
import gleam/string
import layouts/base
import lib/md

pub const value = "a6920af8-2f39-417b-b112-ced60f6d4ba7"

pub const source_url =
  "https://twitter.com/mimifuwacc/status/2075568279989723404"

pub const page_path = "/" <> value

pub const page_url = base.origin <> page_path

pub const text_path = "/uuid.txt"

pub const source_path = "/uuid/source"

pub const fields = [
  #("Version", "4"),
  #("Owned-By", "mst-mkt (Twitter: @mst_mkt_)"),
  #("Issued-By", "mimifuwacc (Twitter: @mimifuwacc)"),
  #("Issued-At", "2026-07-10T13:10:14.800Z"),
]

const hosts = ["uuid.keito.dev", value <> ".keito.dev"]

pub fn text() -> String {
  [#("UUID", value), ..fields]
  |> list.append([#("Source", source_url), #("Page", page_url)])
  |> list.map(fn(field) { field.0 <> ": " <> field.1 <> "\n" })
  |> string.concat
}

pub fn markdown() -> String {
  md.document([
    "# " <> value,
    md.list(list.map(fields, fn(field) { field.0 <> ": " <> field.1 })),
    md.link("Source post", source_url),
  ])
}

pub fn is_host(host: String) -> Bool {
  list.contains(hosts, host)
}
