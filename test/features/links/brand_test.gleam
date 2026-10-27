import features/links/brand.{GitHub}

pub fn from_url_domain_test() {
  let url = "https://github.com/mst-mkt"

  let result = brand.from_url(url)

  assert result == Ok(GitHub)
}

pub fn from_url_subdomain_test() {
  let url = "https://gist.github.com/mst-mkt"

  let result = brand.from_url(url)

  assert result == Ok(GitHub)
}

pub fn from_url_host_case_test() {
  let url = "https://GitHub.com/mst-mkt"

  let result = brand.from_url(url)

  assert result == Ok(GitHub)
}

pub fn from_url_shared_suffix_test() {
  let url = "https://notgithub.com"

  let result = brand.from_url(url)

  assert result == Error(Nil)
}
