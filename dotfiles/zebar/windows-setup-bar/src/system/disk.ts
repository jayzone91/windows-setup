import type {
  Disk,
  DiskOutput,
} from "zebar";

import {
  formatBytes,
} from "../utils/format";

import {
  escapeHtml,
} from "../utils/html";


export function renderDisks(
  diskOutput: DiskOutput,
): string {
  const disks =
    diskOutput.disks.filter(
      (disk) =>
        !disk.isRemovable &&
        disk.totalSpace.bytes > 0,
    );

  return disks
    .map(renderDisk)
    .join("");
}


function renderDisk(
  disk: Disk,
): string {
  const total =
    disk.totalSpace.bytes;

  const available =
    disk.availableSpace.bytes;

  const used =
    total - available;

  const usedPercent =
    total > 0
      ? Math.round(
          (used / total) * 100,
        )
      : 0;

  const mountPoint =
    normalizeMountPoint(
      disk.mountPoint,
    );

  const tooltip =
    `${mountPoint}: ` +
    `${formatBytes(used)} belegt von ` +
    `${formatBytes(total)}`;

  return `
    <div
      class="pill system-pill disk-pill"
      title="${escapeHtml(tooltip)}"
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


function normalizeMountPoint(
  mountPoint: string,
): string {
  return mountPoint
    .replaceAll("\\", "")
    .replaceAll("/", "");
}
