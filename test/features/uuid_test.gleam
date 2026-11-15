import features/uuid

pub fn text_test() {
  let result = uuid.text()

  assert result
    == "UUID: a6920af8-2f39-417b-b112-ced60f6d4ba7\n"
    <> "Version: 4\n"
    <> "Owned-By: mst-mkt (Twitter: @mst_mkt_)\n"
    <> "Issued-By: mimifuwacc (Twitter: @mimifuwacc)\n"
    <> "Issued-At: 2026-07-10T13:10:14.800Z\n"
    <> "Source: https://twitter.com/mimifuwacc/status/2075568279989723404\n"
    <> "Page: https://keito.dev/a6920af8-2f39-417b-b112-ced60f6d4ba7\n"
}

pub fn markdown_test() {
  let result = uuid.markdown()

  assert result
    == "# a6920af8-2f39-417b-b112-ced60f6d4ba7\n\n"
    <> "- Version: 4\n"
    <> "- Owned-By: mst-mkt (Twitter: @mst_mkt_)\n"
    <> "- Issued-By: mimifuwacc (Twitter: @mimifuwacc)\n"
    <> "- Issued-At: 2026-07-10T13:10:14.800Z\n\n"
    <> "[Source post](https://twitter.com/mimifuwacc/status/2075568279989723404)\n"
}

pub fn is_host_uuid_subdomain_test() {
  let host = "uuid.keito.dev"

  let result = uuid.is_host(host)

  assert result
}

pub fn is_host_value_subdomain_test() {
  let host = "a6920af8-2f39-417b-b112-ced60f6d4ba7.keito.dev"

  let result = uuid.is_host(host)

  assert result
}

pub fn is_host_apex_test() {
  let host = "keito.dev"

  let result = uuid.is_host(host)

  assert !result
}
