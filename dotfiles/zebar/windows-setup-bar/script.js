// @ts-check

import * as zebar from "https://esm.sh/zebar@3.3.1";

/**
 * @typedef {import("zebar").KomorebiOutput} KomorebiOutput
 * @typedef {import("zebar").KomorebiWorkspace} KomorebiWorkspace
 * @typedef {import("zebar").KomorebiWindow} KomorebiWindow
 * @typedef {import("zebar").CpuOutput} CpuOutput
 * @typedef {import("zebar").MemoryOutput} MemoryOutput
 * @typedef {import("zebar").DiskOutput} DiskOutput
 * @typedef {import("zebar").Disk} Disk
 */

const providers = zebar.createProviderGroup({
  komorebi: {
    type: "komorebi",
  },
  cpu: {
    type: "cpu",
    refreshInterval: 2000,
  },
  memory: {
    type: "memory",
    refreshInterval: 2000,
  },
  disk: {
    type: "disk",
    refreshInterval: 10000,
  },
});

const layoutIcons = {
  bsp: "󰕰",
  vertical_stack: "󰯌",
  horizontal_stack: "󰯍",
  ultrawide_vertical_stack: "󰯎",
  rows: "󰯋",
  grid: "󰕰",
  right_main_vertical_stack: "󰯏",
  custom: "󰘦",
};

/**
 * @type {Map<string, Promise<string | null>>}
 */
const iconCache = new Map();

/**
 * @type {number | null}
 */
let currentWindowHwnd = null;

/**
 * @template {HTMLElement} T
 * @param {string} id
 * @returns {T}
 */
function getElement(id) {
  const element = document.getElementById(id);

  if (!element) {
    throw new Error(`Element '#${id}' wurde nicht gefunden.`);
  }

  return /** @type {T} */ (element);
}

/**
 * @param {{
 *   komorebi: KomorebiOutput | null;
 *   cpu: CpuOutput | null;
 *   memory: MemoryOutput | null;
 *   disk: DiskOutput | null;
 * }} output
 */
function render(output) {
  const komorebi = output.komorebi;

  if (!komorebi) {
    return;
  }

  renderWorkspaces(komorebi);
  renderLayout(komorebi);
  void renderWindowTitle(komorebi);

  renderSystemStats(output);
}

/**
 * @param {KomorebiOutput} komorebi
 */
function renderWorkspaces(komorebi) {
  const element = getElement("workspaces");

  const workspaces = komorebi.currentWorkspaces ?? [];

  const displayedWorkspace = komorebi.displayedWorkspace;

  element.innerHTML = workspaces
    .map((workspace, index) => {
      const isActive = workspace === displayedWorkspace;

      const name = workspace.name ?? String(index + 1);

      return `
                    <div
                        class="workspace ${isActive ? "active" : ""}"
                    >
                        ${escapeHtml(name)}
                    </div>
                `;
    })
    .join("");
}

/**
 * @param {KomorebiOutput} komorebi
 */
function renderLayout(komorebi) {
  const element = getElement("layout");

  const workspace = komorebi.displayedWorkspace;

  if (!workspace) {
    element.innerHTML = "";
    return;
  }

  const layout = workspace.layout;

  const icon = layoutIcons[layout] ?? "󰘦";

  element.innerHTML = `
        <span
            class="icon"
            title="${escapeHtml(layout)}"
        >
            ${icon}
        </span>
    `;
}

/**
 * @param {KomorebiOutput} komorebi
 * @returns {Promise<void>}
 */
async function renderWindowTitle(komorebi) {
  const element = getElement("window-title");

  const workspace = komorebi.focusedWorkspace;

  const window = getFocusedWindow(workspace);

  if (!window?.title) {
    hideWindowTitle(element);
    return;
  }

  const hwnd = window.hwnd;

  currentWindowHwnd = hwnd;

  const icon = await getWindowIcon(window);

  if (currentWindowHwnd !== hwnd) {
    return;
  }

  element.style.display = "flex";

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

/**
 * @param {KomorebiWorkspace} workspace
 * @returns {KomorebiWindow | null}
 */
function getFocusedWindow(workspace) {
  if (workspace.maximizedWindow) {
    return workspace.maximizedWindow;
  }

  if (workspace.monocleContainer) {
    return workspace.monocleContainer.windows?.[0] ?? null;
  }

  const containers = workspace.tilingContainers ?? [];

  const index = workspace.focusedContainerIndex;

  const container = containers[index];

  if (!container) {
    return null;
  }

  return container.windows?.[0] ?? null;
}

/**
 * @param {HTMLElement} element
 */
function hideWindowTitle(element) {
  element.innerHTML = "";
  element.style.display = "none";
}

/**
 * @param {string | number | null | undefined} value
 * @returns {string}
 */
function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

/**
 * @param {{
 *   cpu: CpuOutput | null;
 *   memory: MemoryOutput | null;
 *   disk: DiskOutput | null;
 * }} output
 */
function renderSystemStats(output) {
  const right = getElement("right");

  const cpu = output.cpu;

  const memory = output.memory;

  const cpuHtml = cpu ? renderCpu(cpu) : "";

  const memoryHtml = memory ? renderMemory(memory) : "";

  const diskHtml = output.disk ? renderDisks(output.disk) : "";

  right.innerHTML = `
        ${cpuHtml}
        ${memoryHtml}
        ${diskHtml}
    `;
}

/**
 * @param {CpuOutput} cpu
 * @returns {string}
 */
function renderCpu(cpu) {
  const usage = Math.round(cpu.usage);

  const highUsageClass = usage >= 85 ? "high-usage" : "";

  return `
        <div
            class="pill system-pill cpu-pill"
            title="CPU-Auslastung"
        >
            <span class="system-icon cpu-icon">
                󰻠
            </span>

            <span class="${highUsageClass}">
                ${usage}%
            </span>
        </div>
    `;
}

/**
 * @param {MemoryOutput} memory
 * @returns {string}
 */
function renderMemory(memory) {
  const usage = Math.round(memory.usage);

  const used = bytesToGiB(memory.usedMemory);

  const total = bytesToGiB(memory.totalMemory);

  return `
        <div
            class="pill system-pill memory-pill"
            title="Arbeitsspeicher"
        >
            <span class="system-icon memory-icon">
                󰍛
            </span>

            <span>
                ${usage}%
            </span>

            <span class="separator">
                ·
            </span>

            <span class="secondary">
                ${used} / ${total} GB
            </span>
        </div>
    `;
}

/**
 * @param {number} bytes
 * @returns {string}
 */
function bytesToGiB(bytes) {
  return (bytes / 1024 / 1024 / 1024).toFixed(1);
}

/**
 * @param {KomorebiWindow} window
 * @returns {Promise<string | null>}
 */
function getWindowIcon(window) {
  const executableName = window.exe?.trim();

  if (!executableName) {
    return Promise.resolve(null);
  }

  const cached = iconCache.get(executableName);

  if (cached) {
    return cached;
  }

  const request = loadWindowIcon(executableName);

  iconCache.set(executableName, request);

  return request;
}

/**
 * @param {string} executableName
 * @returns {Promise<string | null>}
 */
async function loadWindowIcon(executableName) {
  const command = `
        $script = Join-Path $env:USERPROFILE '.glzr\\zebar\\windows-setup-bar\\Get-AppIcon.ps1';

        & $script -ExecutableName $env:ZEBAR_EXECUTABLE
    `;

  try {
    const result = await zebar.shellExec(
      "pwsh",
      ["-NoProfile", "-NonInteractive", "-Command", command],
      {
        env: {
          ZEBAR_EXECUTABLE: executableName,
        },
      },
    );

    if (result.code !== 0) {
      console.error(
        `Icon-Abfrage für ${executableName} fehlgeschlagen:`,
        result.stderr,
      );

      return null;
    }

    const base64 = result.stdout.trim();

    if (!base64) {
      return null;
    }

    return `data:image/png;base64,${base64}`;
  } catch (error) {
    console.error(`Icon-Abfrage für ${executableName} fehlgeschlagen:`, error);

    return null;
  }
}

/**
 * @param {DiskOutput} diskOutput
 * @returns {string}
 */
function renderDisks(diskOutput) {
  const disks = diskOutput.disks.filter((disk) => {
    return !disk.isRemovable && disk.totalSpace.bytes > 0;
  });

  if (disks.length === 0) {
    return "";
  }

  return disks.map((disk) => renderDisk(disk)).join("");
}

/**
 * @param {Disk} disk
 * @returns {string}
 */
function renderDisk(disk) {
  const total = disk.totalSpace.bytes;

  const available = disk.availableSpace.bytes;

  const used = total - available;

  const usedPercent = total > 0 ? Math.round((used / total) * 100) : 0;

  const mountPoint = normalizeMountPoint(disk.mountPoint);

  return `
        <div
            class="pill system-pill disk-pill"
            title="${escapeHtml(
              `${mountPoint}: ${formatBytes(used)} belegt von ${formatBytes(total)}`,
            )}"
        >
            <span class="system-icon disk-icon">
                󰋊
            </span>

            <span class="disk-mount">
                ${escapeHtml(mountPoint)}
            </span>

            <span>
                ${usedPercent}%
            </span>

            <span class="separator">
                ·
            </span>

            <span class="secondary">
                ${formatBytes(used)}
                /
                ${formatBytes(total)}
            </span>
        </div>
    `;
}

/**
 * @param {string} mountPoint
 * @returns {string}
 */
function normalizeMountPoint(mountPoint) {
  return mountPoint.replaceAll("\\", "").replaceAll("/", "");
}

/**
 * @param {number} bytes
 * @returns {string}
 */
function formatBytes(bytes) {
  const gib = bytes / 1024 / 1024 / 1024;

  if (gib >= 1024) {
    return `${(gib / 1024).toFixed(1)} TB`;
  }

  return `${gib.toFixed(0)} GB`;
}

providers.onOutput(() => {
  render(providers.outputMap);
});

render(providers.outputMap);
