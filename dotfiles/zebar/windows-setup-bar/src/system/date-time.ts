const DATE_LOCALE = "de-DE";

const dateFormatter = new Intl.DateTimeFormat(DATE_LOCALE, {
  weekday: "short",
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
});

const timeFormatter = new Intl.DateTimeFormat(DATE_LOCALE, {
  hour: "2-digit",
  minute: "2-digit",
  hour12: false,
});

let updateTimer: number | null = null;

export function renderDateTime(): string {
  const now = new Date();

  return `
    <div
      id="date-time-widget"
      class="pill system-pill date-time-pill"
      title="${formatTooltip(now)}"
    >
      <span class="date-time-icon">
        󰃭
      </span>

      <span
        id="date-time-date"
        class="date-time-date"
      >
        ${dateFormatter.format(now)}
      </span>

      <span class="separator">
        ·
      </span>

      <span
        id="date-time-time"
        class="date-time-time"
      >
        ${timeFormatter.format(now)}
      </span>
    </div>
  `;
}

export function startDateTimeUpdates(): void {
  updateDateTime();

  if (updateTimer !== null) {
    return;
  }

  updateTimer = window.setInterval(updateDateTime, 1000);
}

function updateDateTime(): void {
  const dateElement = document.getElementById("date-time-date");

  const timeElement = document.getElementById("date-time-time");

  const widget = document.getElementById("date-time-widget");

  if (!dateElement || !timeElement || !widget) {
    return;
  }

  const now = new Date();

  dateElement.textContent = dateFormatter.format(now);

  timeElement.textContent = timeFormatter.format(now);

  widget.title = formatTooltip(now);
}

function formatTooltip(date: Date): string {
  return new Intl.DateTimeFormat(DATE_LOCALE, {
    weekday: "long",
    day: "2-digit",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).format(date);
}
