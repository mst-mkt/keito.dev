import gleam/int
import lib/story.{type Story}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Slide {
  Slide(title: String, player: String, width: Int, height: Int)
}

pub fn view(slide: Slide) -> Element(msg) {
  html.iframe([
    attribute.src(slide.player),
    attribute.title(slide.title),
    attribute.loading("lazy"),
    attribute.attribute("allowfullscreen", ""),
    attribute.style(
      "aspect-ratio",
      int.to_string(slide.width) <> " / " <> int.to_string(slide.height),
    ),
    attribute.class("block w-full rounded-lg border border-border bg-control"),
  ])
}

@internal
pub fn stories() -> List(Story) {
  [
    story.new(
      "speakerdeck",
      story.render(
        view(Slide(
          title: "Introduction to SpeakerDeck",
          player: "https://speakerdeck.com/player/50021f75cf1db900020005e7",
          width: 710,
          height: 532,
        )),
      ),
    ),
    story.new(
      "docswell",
      story.render(
        view(Slide(
          title: "Maker Collective Tokyo 2026 Oct - Komori",
          player: "https://www.docswell.com/slide/5VJNN3/embed",
          width: 620,
          height: 349,
        )),
      ),
    ),
  ]
}
