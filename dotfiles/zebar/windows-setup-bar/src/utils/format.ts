export function bytesToGiB(bytes: number): string {
  return (bytes / 1024 / 1024 / 1024).toFixed(1);
}

export function formatBytes(bytes: number): string {
  const gib = bytes / 1024 / 1024 / 1024;

  if (gib >= 1024) {
    return `${(gib / 1024).toFixed(1)} TB`;
  }

  return `${gib.toFixed(0)} GB`;
}
