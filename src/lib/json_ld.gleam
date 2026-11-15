import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Node {
  Person(
    id: String,
    name: String,
    alternate_name: String,
    url: String,
    image: String,
    description: String,
    job_title: String,
    works_for: Organization,
    affiliation: Organization,
    same_as: List(String),
  )
  WebSite(id: String, name: String, url: String, author: PersonReference)
  BlogPosting(
    headline: String,
    url: String,
    image: String,
    language: String,
    published_at: String,
    modified_at: String,
    description: Option(String),
    author: PersonReference,
  )
}

pub type Organization {
  Organization(name: String, url: String)
  CollegeOrUniversity(name: String, url: String)
}

pub type PersonReference {
  PersonReference(id: String, name: String, url: String)
}

pub fn script(nodes: List(Node)) -> Element(msg) {
  let content =
    json.object([
      #("@context", json.string("https://schema.org")),
      #("@graph", json.array(nodes, node_to_json)),
    ])
    |> json.to_string
    |> string.replace("<", "\\u003c")

  html.script([attribute.type_("application/ld+json")], content)
}

fn node_to_json(node: Node) -> Json {
  case node {
    Person(..) ->
      json.object([
        #("@type", json.string("Person")),
        #("@id", json.string(node.id)),
        #("name", json.string(node.name)),
        #("alternateName", json.string(node.alternate_name)),
        #("url", json.string(node.url)),
        #("image", json.string(node.image)),
        #("description", json.string(node.description)),
        #("jobTitle", json.string(node.job_title)),
        #("worksFor", organization_to_json(node.works_for)),
        #("affiliation", organization_to_json(node.affiliation)),
        ..case node.same_as {
          [] -> []
          same_as -> [#("sameAs", json.array(same_as, json.string))]
        }
      ])
    WebSite(..) ->
      json.object([
        #("@type", json.string("WebSite")),
        #("@id", json.string(node.id)),
        #("name", json.string(node.name)),
        #("url", json.string(node.url)),
        #("author", person_reference_to_json(node.author)),
      ])
    BlogPosting(..) ->
      json.object([
        #("@type", json.string("BlogPosting")),
        #("headline", json.string(node.headline)),
        #("url", json.string(node.url)),
        #("mainEntityOfPage", json.string(node.url)),
        #("image", json.string(node.image)),
        #("inLanguage", json.string(node.language)),
        #("datePublished", json.string(node.published_at)),
        #("dateModified", json.string(node.modified_at)),
        #("author", person_reference_to_json(node.author)),
        ..case node.description {
          Some(description) -> [#("description", json.string(description))]
          None -> []
        }
      ])
  }
}

fn organization_to_json(organization: Organization) -> Json {
  let type_ = case organization {
    Organization(..) -> "Organization"
    CollegeOrUniversity(..) -> "CollegeOrUniversity"
  }

  json.object([
    #("@type", json.string(type_)),
    #("name", json.string(organization.name)),
    #("url", json.string(organization.url)),
  ])
}

fn person_reference_to_json(reference: PersonReference) -> Json {
  json.object([
    #("@type", json.string("Person")),
    #("@id", json.string(reference.id)),
    #("name", json.string(reference.name)),
    #("url", json.string(reference.url)),
  ])
}
