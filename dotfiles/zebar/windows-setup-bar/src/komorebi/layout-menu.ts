import type { KomorebiWorkspace } from "zebar";

import { zebar } from "../zebar";

type KomorebiLayout = KomorebiWorkspace["layout"];

type LayoutDefinition = {
  providerId: KomorebiLayout;
  command: string;
  icon: string;
  label: string;
};

const layouts: LayoutDefinition[] = [
  {
    providerId: "bsp",
    command: "bsp",
    icon: "󰕰",
    label: "BSP",
  },
  {
    providerId: "vertical_stack",
    command: "vertical-stack",
    icon: "󰯌",
    label: "Vertical Stack",
  },
  {
    providerId: "horizontal_stack",
    command: "horizontal-stack",
    icon: "󰯍",
    label: "Horizontal Stack",
  },
  {
    providerId: "ultrawide_vertical_stack",
    command: "ultrawide-vertical-stack",
    icon: "󰯎",
    label: "Ultrawide Vertical Stack",
  },
  {
    providerId: "rows",
    command: "rows",
    icon: "󰯋",
    label: "Rows",
  },
  {
    providerId: "grid",
    command: "grid",
    icon: "󰕰",
    label: "Grid",
  },
  {
    providerId: "right_main_vertical_stack",
    command: "right-main-vertical-stack",
    icon: "󰯏",
    label: "Right Main Vertical Stack",
  },
];

const providers = zebar.createProviderGroup({
  komorebi: {
    type: "komorebi",
  },
});

function render(): void {
  const element = document.getElementById("layout-menu");

  if (!element) {
    return;
  }

  const activeLayout = providers.outputMap.komorebi?.displayedWorkspace?.layout;

  element.innerHTML = layouts
    .map((layout) => {
      const active = activeLayout === layout.providerId;

      return `
        <button
          type="button"
          class="layout-option ${active ? "active" : ""}"
          data-layout="${layout.command}"
          aria-label="${layout.label}"
        >
          <span class="layout-option-icon">
            ${layout.icon}
          </span>

          <span class="layout-tooltip">
            ${layout.label}
          </span>
        </button>
      `;
    })
    .join("");

  bindLayoutButtons();
}

function bindLayoutButtons(): void {
  document
    .querySelectorAll<HTMLButtonElement>(".layout-option")
    .forEach((button) => {
      button.addEventListener("click", () => {
        const layout = button.dataset.layout;

        if (!layout) {
          return;
        }

        void changeLayout(layout);
      });
    });
}

async function changeLayout(layout: string): Promise<void> {
  try {
    const result = await zebar.shellExec("komorebic", [
      "change-layout",
      layout,
    ]);

    if (result.code !== 0) {
      console.error(
        `Layout ${layout} konnte nicht gesetzt werden:`,
        result.stderr,
      );

      return;
    }

    await closeMenu();
  } catch (error: unknown) {
    console.error(`Layout ${layout} konnte nicht gesetzt werden:`, error);
  }
}

async function closeMenu(): Promise<void> {
  try {
    await zebar.currentWidget().close();
  } catch (error: unknown) {
    console.error("Layout-Menü konnte nicht geschlossen werden:", error);
  }
}

window.addEventListener("blur", () => {
  void closeMenu();
});

providers.onOutput(() => {
  render();
});

render();
