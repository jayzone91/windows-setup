import type { KomorebiWindow, KomorebiWorkspace } from "zebar";

export function getFocusedWindow(
  workspace: KomorebiWorkspace,
): KomorebiWindow | null {
  if (workspace.maximizedWindow) {
    return workspace.maximizedWindow;
  }

  if (workspace.monocleContainer) {
    return workspace.monocleContainer.windows?.[0] ?? null;
  }

  const container =
    workspace.tilingContainers?.[workspace.focusedContainerIndex];

  if (!container) {
    return null;
  }

  return container.windows?.[0] ?? null;
}
