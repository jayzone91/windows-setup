import fs from "node:fs";
import path from "node:path";
import { Resvg } from "@resvg/resvg-js";

function argument(name) {
  const index = process.argv.indexOf(name);
  if (index === -1 || !process.argv[index + 1]) {
    throw new Error(`Missing argument: ${name}`);
  }

  return path.resolve(process.argv[index + 1]);
}

const themeRoot = argument("--theme-root");
const renderedRoot = argument("--rendered-root");
const outputRoot = argument("--output-root");

const themePath = path.join(themeRoot, "theme.json");
const theme = JSON.parse(fs.readFileSync(themePath, "utf8"));

const iconDefinitions = theme.iconDefinitions ?? {};
const fileExtensions = theme.fileExtensions ?? {};
const fileNames = theme.fileNames ?? {};

fs.rmSync(renderedRoot, { recursive: true, force: true });
fs.rmSync(outputRoot, { recursive: true, force: true });

fs.mkdirSync(renderedRoot, { recursive: true });
fs.mkdirSync(outputRoot, { recursive: true });

const invalidWindowsChars = /[<>:"/\\|?*\u0000-\u001F]/;
const reservedWindowsNames =
  /^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)/i;

const rendered = new Map();
const mapping = [];
const skipped = [];
const collisions = [];

function safeWindowsFilename(value) {
  if (!value) {
    return false;
  }

  if (invalidWindowsChars.test(value)) {
    return false;
  }

  if (reservedWindowsNames.test(value)) {
    return false;
  }

  if (value.endsWith(".") || value.endsWith(" ")) {
    return false;
  }

  return true;
}

function iconDefinition(iconId) {
  return iconDefinitions[iconId] ?? null;
}

function renderIcon(iconId) {
  if (rendered.has(iconId)) {
    return rendered.get(iconId);
  }

  const definition = iconDefinition(iconId);

  if (!definition?.iconPath) {
    skipped.push({
      type: "icon",
      value: iconId,
      reason: "No iconPath in iconDefinitions",
    });

    return null;
  }

  const svgPath = path.resolve(themeRoot, definition.iconPath);

  if (!fs.existsSync(svgPath)) {
    skipped.push({
      type: "icon",
      value: iconId,
      reason: `SVG not found: ${svgPath}`,
    });

    return null;
  }

  const pngPath = path.join(renderedRoot, `${iconId}.png`);
  const svg = fs.readFileSync(svgPath);

  const resvg = new Resvg(svg, {
    fitTo: {
      mode: "width",
      value: 64,
    },
    background: "rgba(0,0,0,0)",
  });

  const png = resvg.render().asPng();
  fs.writeFileSync(pngPath, png);

  rendered.set(iconId, pngPath);

  return pngPath;
}

function hardLink(targetName, iconId, sourceType, sourceValue, priority) {
  if (!safeWindowsFilename(targetName)) {
    skipped.push({
      type: sourceType,
      value: sourceValue,
      targetName,
      reason: "Filename is not valid on Windows",
    });

    return;
  }

  const source = renderIcon(iconId);

  if (!source) {
    return;
  }

  const target = path.join(outputRoot, targetName);
  const existing = mapping.find((item) =>
    item.targetName.toLowerCase() === targetName.toLowerCase(),
  );

  if (existing) {
    if (existing.iconId === iconId) {
      return;
    }

    if (priority <= existing.priority) {
      collisions.push({
        targetName,
        kept: existing.iconId,
        ignored: iconId,
        keptSource: existing.sourceValue,
        ignoredSource: sourceValue,
      });

      return;
    }

    if (fs.existsSync(target)) {
      fs.unlinkSync(target);
    }

    const index = mapping.indexOf(existing);
    mapping.splice(index, 1);
  }

  fs.linkSync(source, target);

  mapping.push({
    targetName,
    iconId,
    sourceType,
    sourceValue,
    priority,
  });
}

/*
 * OneCommander already uses PNG basenames as associations.
 *
 * Extensions:
 *   json -> json.png
 *   yaml -> yaml.png
 *
 * Explicit file names:
 *   .gitignore      -> gitignore.png
 *   package.json    -> package.json.png
 *
 * Exact file-name associations get the higher priority when both would
 * generate the same OneCommander filename.
 */
for (const [extension, iconId] of Object.entries(fileExtensions)) {
  const clean = String(extension).replace(/^\.+/, "").toLowerCase();

  if (!clean) {
    continue;
  }

  hardLink(
    `${clean}.png`,
    iconId,
    "extension",
    extension,
    10,
  );
}

for (const [fileName, iconId] of Object.entries(fileNames)) {
  const clean = String(fileName).replace(/^\.+/, "").toLowerCase();

  if (!clean) {
    continue;
  }

  hardLink(
    `${clean}.png`,
    iconId,
    "filename",
    fileName,
    20,
  );
}

/*
 * A few useful Windows/Unix dotfile aliases which aren't necessarily
 * supplied by vscode-icons as exact fileNames.
 */
const customAliases = [
  ["gitignore_global", [".gitignore", "gitignore"]],
  ["gitconfig", [".gitconfig", "git"]],
  ["yamrc", [".yarnrc", "yarn"]],
  ["yarnrc", [".yarnrc", "yarn"]],
];

function resolveAliasIcon(candidates) {
  for (const candidate of candidates) {
    const exact =
      fileNames[candidate] ??
      fileNames[candidate.toLowerCase()];

    if (exact) {
      return exact;
    }

    if (iconDefinitions[candidate]) {
      return candidate;
    }
  }

  return null;
}

for (const [alias, candidates] of customAliases) {
  const iconId = resolveAliasIcon(candidates);

  if (!iconId) {
    skipped.push({
      type: "custom-alias",
      value: alias,
      reason: `No source icon found (${candidates.join(", ")})`,
    });

    continue;
  }

  hardLink(
    `${alias}.png`,
    iconId,
    "custom-alias",
    alias,
    30,
  );
}

/*
 * Render every remaining Catppuccin icon as well, even if it currently has
 * no file association. This keeps Rendered/CatppuccinMocha a complete,
 * clean upstream-derived icon library.
 */
for (const iconId of Object.keys(iconDefinitions)) {
  renderIcon(iconId);
}

const manifest = {
  generatedAt: new Date().toISOString(),
  themePath,
  statistics: {
    iconDefinitions: Object.keys(iconDefinitions).length,
    renderedIcons: rendered.size,
    extensionAssociations: Object.keys(fileExtensions).length,
    fileNameAssociations: Object.keys(fileNames).length,
    oneCommanderLinks: mapping.length,
    skipped: skipped.length,
    collisions: collisions.length,
  },
  mapping: mapping
    .sort((a, b) => a.targetName.localeCompare(b.targetName))
    .map(({ priority, ...item }) => item),
  skipped,
  collisions,
};

fs.writeFileSync(
  path.join(outputRoot, "_manifest.json"),
  JSON.stringify(manifest, null, 2),
);

console.log("");
console.log("Catppuccin Mocha -> OneCommander");
console.log("--------------------------------");
console.log(`Icon definitions : ${manifest.statistics.iconDefinitions}`);
console.log(`Rendered icons   : ${manifest.statistics.renderedIcons}`);
console.log(`Extensions       : ${manifest.statistics.extensionAssociations}`);
console.log(`Exact filenames  : ${manifest.statistics.fileNameAssociations}`);
console.log(`OneCommander PNG : ${manifest.statistics.oneCommanderLinks}`);
console.log(`Skipped          : ${manifest.statistics.skipped}`);
console.log(`Collisions       : ${manifest.statistics.collisions}`);
console.log("");
