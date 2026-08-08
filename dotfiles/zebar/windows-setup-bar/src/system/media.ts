import type { MediaOutput } from "zebar";

import { escapeHtml } from "../utils/html";

export function renderMedia(media: MediaOutput): string {
  const session = media.currentSession;

  if (!session) {
    return "";
  }

  const title = session.title?.trim() || "Unbekannter Titel";

  const artist = session.artist?.trim();

  const playPauseIcon = session.isPlaying ? "󰏤" : "󰐊";

  return `
    <div
      id="media-widget"
      class="pill system-pill media-pill"
      title="${escapeHtml(artist ? `${title}\n${artist}` : title)}"
    >
      <button
        id="media-previous"
        class="media-control"
        type="button"
        title="Zurück"
      >
        󰒮
      </button>

      <button
        id="media-play-pause"
        class="media-control media-play-pause"
        type="button"
        title="${session.isPlaying ? "Pause" : "Wiedergabe"}"
      >
        ${playPauseIcon}
      </button>

      <button
        id="media-next"
        class="media-control"
        type="button"
        title="Weiter"
      >
        󰒭
      </button>

      <span class="media-info">
        <span class="media-title">
          ${escapeHtml(title)}
        </span>

        ${
          artist
            ? `
              <span class="separator">
                ·
              </span>

              <span class="media-artist">
                ${escapeHtml(artist)}
              </span>
            `
            : ""
        }
      </span>
    </div>
  `;
}

export function bindMediaControls(media: MediaOutput): void {
  const session = media.currentSession;

  if (!session) {
    return;
  }

  const previous = document.getElementById("media-previous");

  const playPause = document.getElementById("media-play-pause");

  const next = document.getElementById("media-next");

  previous?.addEventListener("click", () => {
    media.previous({
      sessionId: session.sessionId,
    });
  });

  playPause?.addEventListener("click", () => {
    media.togglePlayPause({
      sessionId: session.sessionId,
    });
  });

  next?.addEventListener("click", () => {
    media.next({
      sessionId: session.sessionId,
    });
  });
}
