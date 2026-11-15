import { Result$Error, Result$Ok } from "gleam:prelude";

export const isSupported = () => typeof navigator.share === "function";

export const share = (title: string, url: string) => {
  return navigator.share({ title, url }).then(
    () => Result$Ok(undefined),
    (error: DOMException) => Result$Error(error.name),
  );
};
