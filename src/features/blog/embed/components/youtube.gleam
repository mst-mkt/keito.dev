import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type YouTube {
  YouTube(title: String, player: String)
}

pub fn view(youtube: YouTube) -> Element(msg) {
  html.iframe([
    attribute.src(youtube.player),
    attribute.title(youtube.title),
    attribute.loading("lazy"),
    attribute.attribute("allow", "encrypted-media; picture-in-picture"),
    attribute.attribute("allowfullscreen", ""),
    attribute.attribute("referrerpolicy", "strict-origin-when-cross-origin"),
    attribute.class(
      "block aspect-video w-full rounded-lg border border-border bg-control",
    ),
  ])
}

@internal
pub fn stories() -> List(Story) {
  [
    story.new(
      "default",
      story.render(
        view(YouTube(
          title: "アゲアゲパニック / 赤見かるび【MV】",
          player: "https://www.youtube-nocookie.com/embed/iu-DUv-lE4A",
        )),
      ),
    ),
  ]
}
