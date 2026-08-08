import type {
  KomorebiOutput,
} from "zebar";

import {
  getElement,
} from "../utils/dom";

import {
  escapeHtml,
} from "../utils/html";

import {
  getFocusedWindow,
} from "./window-state";

import {
  getWindowIcon,
} from "./window-icon";


let currentWindowHwnd:
  number | null = null;


export async function renderWindowTitle(
  komorebi: KomorebiOutput,
): Promise<void> {
  const element =
    getElement("window-title");

  const workspace =
    komorebi.focusedWorkspace;

  const window =
    getFocusedWindow(workspace);

  if (!window?.title) {
    currentWindowHwnd = null;

    hideWindowTitle(
      element,
    );

    return;
  }

  const hwnd =
    window.hwnd;

  currentWindowHwnd =
    hwnd;

  const icon =
    await getWindowIcon(
      window,
    );

  if (
    currentWindowHwnd !==
    hwnd
  ) {
    return;
  }

  element.style.display =
    "flex";

  element.innerHTML = `
    ${
      icon
        ? `
          <img
            class="window-icon-image"
            src="${icon}"
            alt=""
          />
        `
        : `
          <span class="window-icon">
            󰣆
          </span>
        `
    }

    <span class="window-title-text">
      ${escapeHtml(window.title)}
    </span>
  `;
}


function hideWindowTitle(
  element: HTMLElement,
): void {
  element.innerHTML = "";
  element.style.display =
    "none";
}
