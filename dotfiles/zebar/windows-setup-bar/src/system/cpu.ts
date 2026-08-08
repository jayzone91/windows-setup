import type {
  CpuOutput,
} from "zebar";


export function renderCpu(
  cpu: CpuOutput,
): string {
  const usage =
    Math.round(cpu.usage);

  const highUsageClass =
    usage >= 85
      ? "high-usage"
      : "";

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
