import type {
  KomorebiOutput,
} from "zebar";

import {
  getElement,
} from "../utils/dom";

import {
  escapeHtml,
} from "../utils/html";


export function renderWorkspaces(
  komorebi: KomorebiOutput,
): void {
  const element =
    getElement("workspaces");

  const workspaces =
    komorebi.currentWorkspaces ?? [];

  const displayedWorkspace =
    komorebi.displayedWorkspace;

  element.innerHTML =
    workspaces
      .map((workspace, index) => {
        const isActive =
          workspace ===
          displayedWorkspace;

        const name =
          workspace.name ??
          String(index + 1);

        return `
          <div
            class="workspace ${
              isActive
                ? "active"
                : ""
            }"
          >
            ${escapeHtml(name)}
          </div>
        `;
      })
      .join("");
}
