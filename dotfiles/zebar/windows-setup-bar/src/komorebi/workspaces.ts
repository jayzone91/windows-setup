import type { KomorebiOutput } from "zebar";

import { getElement } from "../utils/dom";
import { escapeHtml } from "../utils/html";
import { zebar } from "../zebar";

async function focusWorkspace(index: number): Promise<void> {
  try {
    const result = await zebar.shellExec("komorebic", [
      "focus-workspace",
      String(index),
    ]);

    if (result.code !== 0) {
      console.error(
        `Workspace ${index} konnte nicht fokussiert werden:`,
        result.stderr,
      );
    }
  } catch (error: unknown) {
    console.error(`Workspace ${index} konnte nicht fokussiert werden:`, error);
  }
}

export function renderWorkspaces(komorebi: KomorebiOutput): void {
  const element = getElement("workspaces");

  const workspaces = komorebi.currentWorkspaces ?? [];
  const displayedWorkspace = komorebi.displayedWorkspace;

  element.innerHTML = workspaces
    .map((workspace, index) => {
      const isActive = workspace === displayedWorkspace;
      const name = workspace.name ?? String(index + 1);

      return `
        <button
          type="button"
          class="workspace ${isActive ? "active" : ""}"
          data-workspace="${index}"
          title="Workspace ${escapeHtml(name)}"
        >
          ${escapeHtml(name)}
        </button>
      `;
    })
    .join("");

  element
    .querySelectorAll<HTMLButtonElement>(".workspace")
    .forEach((button) => {
      button.addEventListener("click", () => {
        const workspace = Number(button.dataset.workspace);

        if (!Number.isInteger(workspace)) {
          return;
        }

        void focusWorkspace(workspace);
      });
    });
}
