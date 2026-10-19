import { cn } from "cn";
import type { List } from "gleam:prelude";

export const from_list = (classes: List<string>): string => cn(...classes);
