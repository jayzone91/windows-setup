import type {
  KomorebiWindow,
} from "zebar";

import {
  zebar,
} from "../zebar";


const iconCache =
  new Map<
    string,
    Promise<string | null>
  >();


export function getWindowIcon(
  window: KomorebiWindow,
): Promise<string | null> {
  const executableName =
    window.exe?.trim();

  if (!executableName) {
    return Promise.resolve(null);
  }

  const cached =
    iconCache.get(
      executableName,
    );

  if (cached) {
    return cached;
  }

  const request =
    loadWindowIcon(
      executableName,
    );

  iconCache.set(
    executableName,
    request,
  );

  return request;
}


async function loadWindowIcon(
  executableName: string,
): Promise<string | null> {
  const command = `
    $script = Join-Path $env:USERPROFILE '.glzr\\zebar\\windows-setup-bar\\Get-AppIcon.ps1';

    & $script -ExecutableName $env:ZEBAR_EXECUTABLE
  `;

  try {
    const result =
      await zebar.shellExec(
        "pwsh",
        [
          "-NoProfile",
          "-NonInteractive",
          "-Command",
          command,
        ],
        {
          env: {
            ZEBAR_EXECUTABLE:
              executableName,
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

    const base64 =
      result.stdout.trim();

    if (!base64) {
      return null;
    }

    return (
      `data:image/png;base64,${base64}`
    );
  }
  catch (error: unknown) {
    console.error(
      `Icon-Abfrage für ${executableName} fehlgeschlagen:`,
      error,
    );

    return null;
  }
}
