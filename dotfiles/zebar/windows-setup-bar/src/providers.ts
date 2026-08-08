import { zebar } from "./zebar";

export const providers = zebar.createProviderGroup({
  komorebi: {
    type: "komorebi",
  },

  cpu: {
    type: "cpu",
    refreshInterval: 2000,
  },

  memory: {
    type: "memory",
    refreshInterval: 2000,
  },

  disk: {
    type: "disk",
    refreshInterval: 10000,
  },

  network: {
    type: "network",
    refreshInterval: 2000,
  },

  audio: {
    type: "audio",
  },

  media: {
    type: "media",
  },
});
