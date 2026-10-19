import type { __unstable__loadDesignSystem } from "@tailwindcss/node";

type DesignSystem = Awaited<ReturnType<typeof __unstable__loadDesignSystem>>;

export const get_class_order = (design: DesignSystem, classes: string[]) => {
  return design.getClassOrder(classes);
};
