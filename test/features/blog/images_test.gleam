import features/blog/images.{Size}

pub fn srcset_test() {
  assert images.srcset("/blog/a/b.webp", Size(width: 2674, height: 1504))
    == "https://keito.dev/cdn-cgi/image/width=640,format=auto/blog/a/b.webp 640w, https://keito.dev/cdn-cgi/image/width=750,format=auto/blog/a/b.webp 750w, https://keito.dev/cdn-cgi/image/width=828,format=auto/blog/a/b.webp 828w, https://keito.dev/cdn-cgi/image/width=1080,format=auto/blog/a/b.webp 1080w, https://keito.dev/cdn-cgi/image/width=1200,format=auto/blog/a/b.webp 1200w, https://keito.dev/cdn-cgi/image/width=1920,format=auto/blog/a/b.webp 1920w"
}

pub fn srcset_small_image_test() {
  assert images.srcset("/blog/a/b.webp", Size(width: 800, height: 400))
    == "https://keito.dev/cdn-cgi/image/width=640,format=auto/blog/a/b.webp 640w, https://keito.dev/cdn-cgi/image/width=750,format=auto/blog/a/b.webp 750w, https://keito.dev/cdn-cgi/image/width=800,format=auto/blog/a/b.webp 800w"
}
