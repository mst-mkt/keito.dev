type Meta = { name: string | null; property: string | null; content: string | null };

type Link = { rel: string | null; href: string | null };

export const read = async (body: Response) => {
  let base: string | null = null;
  const titles: string[] = [];
  const metas: Meta[] = [];
  const links: Link[] = [];
  let headEnded = false;

  const transformed = new HTMLRewriter()
    .on("base", {
      element: (element) => {
        base ??= element.getAttribute("href");
      },
    })
    .on("title", {
      element: () => {
        titles.push("");
      },
      text: (chunk) => {
        titles[titles.length - 1] += chunk.text;
      },
    })
    .on("meta", {
      element: (element) => {
        metas.push({
          name: element.getAttribute("name"),
          property: element.getAttribute("property"),
          content: element.getAttribute("content"),
        });
      },
    })
    .on("link", {
      element: (element) => {
        links.push({ rel: element.getAttribute("rel"), href: element.getAttribute("href") });
      },
    })
    .on("head", {
      element: (element) => {
        element.onEndTag(() => {
          headEnded = true;
        });
      },
    })
    .transform(body);

  for await (const _chunk of transformed.body ?? []) {
    if (headEnded) break;
  }

  return { base, titles, metas, links };
};
