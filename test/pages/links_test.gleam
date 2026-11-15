import features/links/link.{Link}
import pages/links

pub fn markdown_view_test() {
  let items = [
    Link(id: "github", name: "GitHub", url: "https://github.com/mst-mkt"),
    Link(id: "twitter", name: "Twitter", url: "https://x.com/mst_mkt_"),
  ]

  let result = links.markdown_view(items)

  assert result
    == "# Links\n\n- [GitHub](https://github.com/mst-mkt)\n- [Twitter](https://x.com/mst_mkt_)\n"
}

pub fn markdown_view_without_links_test() {
  let result = links.markdown_view([])

  assert result == "# Links\n\nNo links.\n"
}
