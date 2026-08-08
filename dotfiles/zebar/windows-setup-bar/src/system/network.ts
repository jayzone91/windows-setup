import type { NetworkInterface, NetworkOutput } from "zebar";

import { escapeHtml } from "../utils/html";

export function renderNetwork(network: NetworkOutput): string {
  const networkInterface = network.defaultInterface;

  if (!networkInterface) {
    return "";
  }

  const ipv4 = getPrimaryIpv4(networkInterface);

  const received = network.traffic
    ? formatNetworkRate(network.traffic.received.bytes)
    : "0 B/s";

  const transmitted = network.traffic
    ? formatNetworkRate(network.traffic.transmitted.bytes)
    : "0 B/s";

  const interfaceName = formatInterfaceType(networkInterface.type);

  const tooltipParts = [
    networkInterface.friendlyName,
    networkInterface.description,
    ipv4 ? `IPv4: ${ipv4}` : null,
  ].filter((value): value is string => Boolean(value));

  return `
    <div
      class="pill system-pill network-pill"
      title="${escapeHtml(tooltipParts.join("\n"))}"
    >
      <span class="system-icon network-icon">
        ${getNetworkIcon(networkInterface)}
      </span>

      <span class="network-interface">
        ${escapeHtml(interfaceName ? (interfaceName === "Ethernet" ? "LAN" : interfaceName) : networkInterface.friendlyName)}
      </span>

      ${
        ipv4
          ? `
            <span class="separator">
              ·
            </span>

            <span class="secondary network-ip">
              ${escapeHtml(ipv4)}
            </span>
          `
          : ""
      }

      <span class="separator">
        ·
      </span>

      <span class="network-download">
        󰇚 ${received}
      </span>

      <span class="network-upload">
        󰕒 ${transmitted}
      </span>
    </div>
  `;
}

function getPrimaryIpv4(networkInterface: NetworkInterface): string | null {
  return (
    networkInterface.ipv4Addresses.find(
      (address) => !address.startsWith("169.254."),
    ) ?? null
  );
}

function formatInterfaceType(type: NetworkInterface["type"]): string {
  switch (type) {
    case "ethernet":
      return "Ethernet";

    case "wifi":
      return "WLAN";

    case "mobile_broadband":
      return "Mobilfunk";

    case "dsl":
      return "DSL";

    case "tunnel":
      return "Tunnel";

    case "bridge":
      return "Bridge";

    default:
      return "Netzwerk";
  }
}

function getNetworkIcon(networkInterface: NetworkInterface): string {
  switch (networkInterface.type) {
    case "wifi":
      return "󰖩";

    case "ethernet":
      return "󰈀";

    default:
      return "󰛳";
  }
}

function formatNetworkRate(bytesPerSecond: number): string {
  if (bytesPerSecond >= 1_000_000_000) {
    return `${(bytesPerSecond / 1_000_000_000).toFixed(1)} GB/s`;
  }

  if (bytesPerSecond >= 1_000_000) {
    return `${(bytesPerSecond / 1_000_000).toFixed(1)} MB/s`;
  }

  if (bytesPerSecond >= 1_000) {
    return `${(bytesPerSecond / 1_000).toFixed(1)} KB/s`;
  }

  return `${Math.round(bytesPerSecond)} B/s`;
}
