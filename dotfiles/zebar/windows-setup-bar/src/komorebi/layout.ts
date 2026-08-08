import type { KomorebiOutput, KomorebiWorkspace } from "zebar";

import { getElement } from "../utils/dom";
import { escapeHtml } from "../utils/html";
import { zebar } from "../zebar";

type KomorebiLayout = KomorebiWorkspace["layout"];

export const layoutIcons: Record<KomorebiLayout, string> = {
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

  element.onclick = () => {
    void openLayoutMenu();
  };
}

async function openLayoutMenu(): Promise<void> {
  try {
    await zebar.startWidgetPreset("layout-menu", "default");
  } catch (error: unknown) {
    console.error("Layout-Menü konnte nicht geöffnet werden:", error);
  }
}
