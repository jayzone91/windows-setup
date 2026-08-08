import type { KomorebiOutput, KomorebiWorkspace } from "zebar";

import { getElement } from "../utils/dom";

import { escapeHtml } from "../utils/html";

type KomorebiLayout = KomorebiWorkspace["layout"];

const layoutIcons: Record<KomorebiLayout, string> = {
  bsp: "󰕰",
  vertical_stack: "󰯌",
  horizontal_stack: "󰯍",
  ultrawide_vertical_stack: "󰯎",
  rows: "󰯋",
  grid: "󰕰",
  right_main_vertical_stack: "󰯏",
  custom: "󰘦",
};

export function renderLayout(komorebi: KomorebiOutput): void {
  const element = getElement("layout");

  const workspace = komorebi.displayedWorkspace;

  if (!workspace) {
    element.innerHTML = "";
    return;
  }

  const layout = workspace.layout;

  const icon = layoutIcons[layout];

  element.innerHTML = `
    <span
      class="icon"
      title="${escapeHtml(layout)}"
    >
      ${icon}
    </span>
  `;
}
