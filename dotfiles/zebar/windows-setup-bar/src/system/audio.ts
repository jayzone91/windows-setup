import type { AudioOutput } from "zebar";

import { escapeHtml } from "../utils/html";

const VOLUME_STEP = 2;

export function renderAudio(audio: AudioOutput): string {
  const device = audio.defaultPlaybackDevice;

  if (!device) {
    return "";
  }

  const volume = Math.round(device.volume);

  const icon = getVolumeIcon(volume, device.isMuted);

  return `
    <div
      id="audio-widget"
      class="pill system-pill audio-pill"
      title="${escapeHtml(`${device.name}\nKlick: Stumm\nMausrad: Lautstärke`)}"
    >
      <span
        class="system-icon audio-icon ${device.isMuted ? "muted" : ""}"
      >
        ${icon}
      </span>

      <span class="audio-volume">
        ${device.isMuted ? "Mute" : `${volume}%`}
      </span>
    </div>
  `;
}

export function bindAudioControls(audio: AudioOutput): void {
  const element = document.getElementById("audio-widget");

  const device = audio.defaultPlaybackDevice;

  if (!element || !device) {
    return;
  }

  element.addEventListener("click", () => {
    void audio.setMute(!device.isMuted);
  });

  element.addEventListener(
    "wheel",
    (event) => {
      event.preventDefault();

      const direction = event.deltaY < 0 ? 1 : -1;

      const newVolume = clampVolume(device.volume + direction * VOLUME_STEP);

      void audio.setVolume(newVolume);
    },
    {
      passive: false,
    },
  );
}

function getVolumeIcon(volume: number, isMuted: boolean): string {
  if (isMuted || volume === 0) {
    return "󰝟";
  }

  if (volume < 35) {
    return "󰕿";
  }

  if (volume < 70) {
    return "󰖀";
  }

  return "󰕾";
}

function clampVolume(volume: number): number {
  return Math.min(100, Math.max(0, Math.round(volume)));
}
