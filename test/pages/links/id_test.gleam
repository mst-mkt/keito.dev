import features/links/link.{Link}
import pages/links/id

pub fn markdown_view_test() {
  let current =
    Link(id: "github", name: "GitHub", url: "https://github.com/mst-mkt")

  let result = id.markdown_view(current)

  assert result
    == "# GitHub\n\n- Link: [github.com/mst-mkt](https://github.com/mst-mkt)\n- Short link: [keito.dev/l/github](https://keito.dev/l/github)\n"
}
