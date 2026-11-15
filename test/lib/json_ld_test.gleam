import gleam/option.{type Option, None, Some}
import gleam/string
import lib/json_ld.{
  BlogPosting, CollegeOrUniversity, Organization, Person, PersonReference,
  WebSite,
}
import lustre/element

const author =
  PersonReference(id: "https://a.com/#person", name: "A", url: "https://a.com/")

fn person(same_as: List(String)) -> json_ld.Node {
  Person(
    id: "https://a.com/#person",
    name: "A",
    alternate_name: "a",
    url: "https://a.com/",
    image: "https://a.com/a.png",
    description: "B",
    job_title: "C",
    works_for: Organization("D", "https://d.com/"),
    affiliation: CollegeOrUniversity("E", "https://e.com/"),
    same_as:,
  )
}

fn blog_posting(description: Option(String)) -> json_ld.Node {
  BlogPosting(
    headline: "B",
    url: "https://a.com/b",
    image: "https://a.com/b.png",
    language: "ja",
    published_at: "2025-11-15",
    modified_at: "2025-12-07",
    description:,
    author:,
  )
}

fn render(nodes: List(json_ld.Node)) -> String {
  element.to_string(json_ld.script(nodes))
}

pub fn script_graph_test() {
  let nodes = [
    WebSite(
      id: "https://a.com/#website",
      name: "A",
      url: "https://a.com/",
      author:,
    ),
  ]

  let result = render(nodes)

  assert result
    == "<script type=\"application/ld+json\">{\"@context\":\"https://schema.org\",\"@graph\":[{\"@type\":\"WebSite\",\"@id\":\"https://a.com/#website\",\"name\":\"A\",\"url\":\"https://a.com/\",\"author\":{\"@type\":\"Person\",\"@id\":\"https://a.com/#person\",\"name\":\"A\",\"url\":\"https://a.com/\"}}]}</script>"
}

pub fn script_escape_test() {
  let nodes = [
    WebSite(
      id: "https://a.com/#website",
      name: "</script>",
      url: "https://a.com/",
      author:,
    ),
  ]

  let result = render(nodes)

  assert string.contains(result, "\"name\":\"\\u003c/script>\"")
}

pub fn script_description_test() {
  let nodes = [blog_posting(Some("C"))]

  let result = render(nodes)

  assert string.contains(result, "\"description\":\"C\"")
}

pub fn script_without_description_test() {
  let nodes = [blog_posting(None)]

  let result = render(nodes)

  assert !string.contains(result, "\"description\"")
}

pub fn script_same_as_test() {
  let nodes = [person(["https://b.com/a"])]

  let result = render(nodes)

  assert string.contains(result, "\"sameAs\":[\"https://b.com/a\"]")
}

pub fn script_without_same_as_test() {
  let nodes = [person([])]

  let result = render(nodes)

  assert !string.contains(result, "\"sameAs\"")
}

pub fn script_organization_test() {
  let nodes = [person([])]

  let result = render(nodes)

  assert string.contains(result, "\"worksFor\":{\"@type\":\"Organization\"")
  assert string.contains(
    result,
    "\"affiliation\":{\"@type\":\"CollegeOrUniversity\"",
  )
}
