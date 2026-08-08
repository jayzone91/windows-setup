import type { MemoryOutput } from "zebar";

import { bytesToGiB } from "../utils/format";

export function renderMemory(memory: MemoryOutput): string {
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
