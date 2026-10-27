import { createCn } from "cn/engine";
import tables from "#cn-tables";
import type { List } from "gleam:prelude";

const cn = createCn(tables);

export const from_list = (classes: List<string>): string => cn(...classes);
