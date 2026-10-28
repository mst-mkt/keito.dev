import { Result$Error, Result$Ok } from "gleam:prelude";

export const reader = () => {
  return "NDEFReader" in globalThis ? Result$Ok(new NDEFReader()) : Result$Error(undefined);
};

export const writeUrl = (reader: NDEFReader, url: string) => {
  return reader.write({ records: [{ recordType: "url", data: url }] });
};
