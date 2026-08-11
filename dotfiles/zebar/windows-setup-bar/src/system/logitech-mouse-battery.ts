import { zebar } from "../zebar";

const POLL_INTERVAL_MS = 30_000;

interface MouseBatteryState {
  percentage: number;
  charging: boolean;
  fullyCharged: boolean;
  criticalLevel: boolean;
  usbConnected: boolean;
}

interface BatteryCommandOutput {
  device?: string;
  percentage?: number;
  charging?: boolean;
  fullyCharged?: boolean;
  criticalLevel?: boolean;
  usbConnected?: boolean;
}

let state: MouseBatteryState | null = null;
let started = false;
let pollTimer: number | null = null;
let requestRunning = false;
let notifyChange: (() => void) | null = null;

function setState(nextState: MouseBatteryState | null): void {
  if (
    state?.percentage === nextState?.percentage &&
    state?.charging === nextState?.charging &&
    state?.fullyCharged === nextState?.fullyCharged &&
    state?.criticalLevel === nextState?.criticalLevel &&
    state?.usbConnected === nextState?.usbConnected
  ) {
    return;
  }

  state = nextState;
  notifyChange?.();
}

async function refreshBatteryState(): Promise<void> {
  if (requestRunning) {
    return;
  }

  requestRunning = true;

  const command = `
    $script = Join-Path $env:USERPROFILE '.glzr\\zebar\\windows-setup-bar\\Get-LogitechMouseBattery.ps1';

    & $script
  `;

  try {
    const result = await zebar.shellExec(
      "pwsh",
      ["-NoProfile", "-NonInteractive", "-Command", command],
    );

    if (result.code !== 0) {
      console.error(
        "Logitech-Maus-Akkuabfrage fehlgeschlagen:",
        result.stderr,
      );

      setState(null);
      return;
    }

    const stdout = result.stdout.trim();

    if (!stdout) {
      setState(null);
      return;
    }

    let output: BatteryCommandOutput;

    try {
      output = JSON.parse(stdout) as BatteryCommandOutput;
    } catch (error: unknown) {
      console.error(
        "Ungültige Ausgabe der Logitech-Maus-Akkuabfrage:",
        stdout,
        error,
      );

      setState(null);
      return;
    }

    if (
      typeof output.percentage !== "number" ||
      typeof output.charging !== "boolean" ||
      typeof output.fullyCharged !== "boolean" ||
      typeof output.criticalLevel !== "boolean" ||
      typeof output.usbConnected !== "boolean"
    ) {
      console.error(
        "Unvollständige Logitech-Maus-Akkudaten:",
        output,
      );

      setState(null);
      return;
    }

    setState({
      percentage: Math.max(0, Math.min(100, Math.round(output.percentage))),
      charging: output.charging,
      fullyCharged: output.fullyCharged,
      criticalLevel: output.criticalLevel,
      usbConnected: output.usbConnected,
    });
  } catch (error: unknown) {
    console.error("Logitech-Maus-Akkuabfrage fehlgeschlagen:", error);
    setState(null);
  } finally {
    requestRunning = false;
  }
}

export function startLogitechMouseBatteryMonitor(
  onChange: () => void,
): void {
  notifyChange = onChange;

  if (started) {
    return;
  }

  started = true;

  void refreshBatteryState();

  pollTimer = window.setInterval(() => {
    void refreshBatteryState();
  }, POLL_INTERVAL_MS);
}

export function renderLogitechMouseBattery(): string {
  if (!state) {
    return "";
  }

  const levelClass =
    state.criticalLevel
      ? "critical"
      : state.percentage <= 30
        ? "low"
        : "";

  const usbIcon = state.usbConnected
    ? `
      <span
        class="system-icon mouse-battery-status-icon mouse-battery-usb-icon"
        title="USB verbunden"
        aria-label="USB verbunden"
      >
        󰕓
      </span>
    `
    : "";

  const chargingIcon = state.charging
    ? `
      <span
        class="mouse-battery-charge-icon charging"
        title="Wird geladen"
        aria-label="Wird geladen"
      >
        <span class="mouse-battery-charge-base" aria-hidden="true">
          󱐋
        </span>
        <span class="mouse-battery-charge-fill" aria-hidden="true">
          󱐋
        </span>
      </span>
    `
    : state.fullyCharged
      ? `
        <span
          class="system-icon mouse-battery-status-icon mouse-battery-charge-full"
          title="Vollständig geladen"
          aria-label="Vollständig geladen"
        >
          󱐋
        </span>
      `
      : "";

  const title = state.fullyCharged
    ? "Logitech G502 X Plus – vollständig geladen"
    : state.charging
      ? "Logitech G502 X Plus – wird geladen"
      : state.criticalLevel
        ? "Logitech G502 X Plus – kritischer Akkustand"
        : "Logitech G502 X Plus";

  return `
    <div
      class="pill system-pill mouse-battery-pill"
      title="${title}"
    >
      <span
        class="system-icon mouse-battery-icon"
        aria-label="Logitech G502 X Plus"
      >
        󰍽
      </span>

      ${usbIcon}
      ${chargingIcon}

      <span class="mouse-battery-level ${levelClass}">
        ${state.percentage}%
      </span>
    </div>
  `;
}