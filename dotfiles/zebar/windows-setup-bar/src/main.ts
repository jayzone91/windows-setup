import {
  providers,
} from "./providers";

import {
  getElement,
} from "./utils/dom";

import {
  renderLayout,
} from "./komorebi/layout";

import {
  renderWindowTitle,
} from "./komorebi/window-title";

import {
  renderWorkspaces,
} from "./komorebi/workspaces";

import {
  renderCpu,
} from "./system/cpu";

import {
  renderDisks,
} from "./system/disk";

import {
  renderMemory,
} from "./system/memory";


type ProviderOutput =
  typeof providers.outputMap;


function render(
  output: ProviderOutput,
): void {
  if (output.komorebi) {
    renderWorkspaces(
      output.komorebi,
    );

    renderLayout(
      output.komorebi,
    );

    void renderWindowTitle(
      output.komorebi,
    );
  }

  renderRight(output);
}


function renderRight(
  output: ProviderOutput,
): void {
  const right =
    getElement("right");

  right.innerHTML = `
    ${
      output.cpu
        ? renderCpu(
            output.cpu,
          )
        : ""
    }

    ${
      output.memory
        ? renderMemory(
            output.memory,
          )
        : ""
    }

    ${
      output.disk
        ? renderDisks(
            output.disk,
          )
        : ""
    }
  `;
}


providers.onOutput(() => {
  render(
    providers.outputMap,
  );
});


render(
  providers.outputMap,
);
