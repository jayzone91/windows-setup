import fs from "node:fs";
import os from "node:os";
import crypto from "node:crypto";
import zlib from "node:zlib";
import path from "node:path";

function fail(message) {
  console.error(`[ERROR] ${message}`);
  process.exit(1);
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) fail(`Umgebungsvariable fehlt: ${name}`);
  return value;
}

function readEnvelope(inputPath) {
  let envelope;

  try {
    envelope = JSON.parse(
      zlib.gunzipSync(fs.readFileSync(inputPath)).toString("utf8"),
    );
  } catch {
    fail("Der äußere Raycast-Container konnte nicht gelesen werden.");
  }

  if (envelope.schemaVersion !== 2) {
    fail(`Nicht unterstützte Raycast-Schema-Version: ${envelope.schemaVersion}`);
  }

  if (
    !envelope.encryption?.salt ||
    !envelope.encryption?.iv ||
    !envelope.encryption?.authTag ||
    !envelope.data
  ) {
    fail("Der Raycast-Export besitzt nicht die erwartete Schema-v2-Struktur.");
  }

  return envelope;
}

function decryptPayload(envelope, password) {
  const key = crypto.scryptSync(
    password,
    Buffer.from(envelope.encryption.salt, "hex"),
    32,
  );

  const decipher = crypto.createDecipheriv(
    "aes-256-gcm",
    key,
    Buffer.from(envelope.encryption.iv, "hex"),
  );

  decipher.setAuthTag(Buffer.from(envelope.encryption.authTag, "hex"));

  let compressed;

  try {
    compressed = Buffer.concat([
      decipher.update(Buffer.from(envelope.data, "hex")),
      decipher.final(),
    ]);
  } catch {
    fail("Raycast-Export konnte nicht entschlüsselt werden. ExportPassword prüfen.");
  }

  try {
    return JSON.parse(zlib.gunzipSync(compressed).toString("utf8"));
  } catch {
    fail("Der entschlüsselte Raycast-Payload ist ungültig.");
  }
}

function sanitize(source, envelope) {
  if (source.settings?.schemaVersion !== 1) {
    fail(`Nicht unterstütztes Settings-Schema: ${source.settings?.schemaVersion}`);
  }

  if (source.nodeExtensions?.schemaVersion !== 1) {
    fail(
      `Nicht unterstütztes Extension-Schema: ${source.nodeExtensions?.schemaVersion}`,
    );
  }

  const allowedGeneralKeys = [
    "openAtLogin",
    "showInMenuBar",
    "appearance",
    "themeDarkId",
    "windowMode",
    "windowPresentationMode",
    "windowActivationBehavior",
    "globalHotkey",
    "popToRootTimeout",
    "escapeKeyBehavior",
    "navigationBindings",
    "pageNavigationKeys",
    "useSystemProxySettings",
    "additionalCertificateAuthorities",
    "rootSearchSensitivity",
    "builtinHotkeysPreset",
  ];

  const general = {};
  for (const key of allowedGeneralKeys) {
    if (source.settings.general?.[key] !== undefined) {
      general[key] = source.settings.general[key];
    }
  }

  const extensions = (source.nodeExtensions.extensions ?? []).map((extension) => {
    const clean = {};
    for (const key of ["uuid", "name", "author", "owner"]) {
      if (extension[key] !== undefined) clean[key] = extension[key];
    }
    return clean;
  });

  const extensionIds = new Set(
    extensions
      .filter((extension) => extension.uuid)
      .map((extension) => `e:n:${extension.uuid}`),
  );

  const nodeExtensionSettings = (source.settings.nodeExtensions ?? [])
    .filter((extension) => extensionIds.has(extension.id))
    .map((extension) => ({
      id: extension.id,
      enabled: extension.enabled !== false,
    }));

  const allowedCommandKeys = [
    "id",
    "extensionId",
    "enabled",
    "alias",
    "favoriteOrder",
    "windowsHotkey",
  ];

  const commands = (source.settings.commands ?? [])
    .filter((command) => extensionIds.has(command.extensionId))
    .map((command) => {
      const clean = {};
      for (const key of allowedCommandKeys) {
        if (command[key] !== undefined) clean[key] = command[key];
      }
      return clean;
    });

  const desired = {
    schemaVersion: 1,
    raycast: {
      sourceSchemaVersion: envelope.schemaVersion,
      settings: {
        schemaVersion: source.settings.schemaVersion,
        general,
        themes: source.settings.themes ?? [],
        nodeExtensions: nodeExtensionSettings,
        commands,
        internalExtensions: [],
        frecency: [],
      },
      nodeExtensions: {
        schemaVersion: source.nodeExtensions.schemaVersion,
        extensions,
      },
    },
  };

  const forbiddenKeys = new Set([
    "oauthTokens",
    "localStorage",
    "storedValues",
    "aiByokApiKeys",
    "apiKey",
    "accessToken",
    "refreshToken",
    "idToken",
    "password",
    "proxyPassword",
    "credential",
    "credentials",
    "cookie",
    "cookies",
  ]);

  function inspect(value, path = "$") {
    if (Array.isArray(value)) {
      value.forEach((item, index) => inspect(item, `${path}[${index}]`));
      return;
    }

    if (!value || typeof value !== "object") return;

    for (const [key, child] of Object.entries(value)) {
      const childPath = `${path}.${key}`;
      if (forbiddenKeys.has(key)) {
        fail(`Verbotenes Feld im Desired State: ${childPath}`);
      }
      inspect(child, childPath);
    }
  }

  inspect(desired);
  return desired;
}

function buildImport(desired, password, outputPath) {
  if (desired.schemaVersion !== 1) {
    fail(`Nicht unterstütztes Desired-State-Schema: ${desired.schemaVersion}`);
  }

  if (desired.raycast?.sourceSchemaVersion !== 2) {
    fail(
      `Nicht unterstütztes Raycast-Zielschema: ${desired.raycast?.sourceSchemaVersion}`,
    );
  }

  if (desired.raycast.settings?.schemaVersion !== 1) {
    fail("Settings-Schema im Desired State muss Version 1 sein.");
  }

  if (desired.raycast.nodeExtensions?.schemaVersion !== 1) {
    fail("Extension-Schema im Desired State muss Version 1 sein.");
  }

  const payload = {
    settings: desired.raycast.settings,
    nodeExtensions: desired.raycast.nodeExtensions,
  };

  const compressed = zlib.gzipSync(
    Buffer.from(JSON.stringify(payload), "utf8"),
  );

  const salt = crypto.randomBytes(16);
  const iv = crypto.randomBytes(16);
  const key = crypto.scryptSync(password, salt, 32);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([cipher.update(compressed), cipher.final()]);
  const authTag = cipher.getAuthTag();

  const envelope = {
    appVersion: process.env.RAYCAST_APP_VERSION || "unknown",
    data: encrypted.toString("hex"),
    encryption: {
      authTag: authTag.toString("hex"),
      iv: iv.toString("hex"),
      salt: salt.toString("hex"),
    },
    exportedAt: new Date().toISOString(),
    osArch: os.arch(),
    osName: "Windows",
    osVersion: os.release(),
    schemaVersion: 2,
  };
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, zlib.gzipSync(Buffer.from(JSON.stringify(envelope))));
}

const action = process.argv[2];

if (action === "sanitize") {
  const inputPath = requireEnv("RAYCAST_INPUT_PATH");
  const outputPath = requireEnv("RAYCAST_OUTPUT_PATH");
  const password = requireEnv("RAYCAST_EXPORT_PASSWORD");
  const envelope = readEnvelope(inputPath);
  const source = decryptPayload(envelope, password);
  const desired = sanitize(source, envelope);
  fs.writeFileSync(outputPath, `${JSON.stringify(desired, null, 2)}\n`, "utf8");
  console.log(`[OK] Raycast Desired State erzeugt: ${outputPath}`);
} else if (action === "build") {
  const inputPath = requireEnv("RAYCAST_INPUT_PATH");
  const outputPath = requireEnv("RAYCAST_OUTPUT_PATH");
  const password = requireEnv("RAYCAST_EXPORT_PASSWORD");
  const desired = JSON.parse(fs.readFileSync(inputPath, "utf8"));
  buildImport(desired, password, outputPath);
  console.log(`[OK] Lokales Raycast-Importarchiv erzeugt: ${outputPath}`);
} else {
  fail(`Unbekannte Aktion: ${action}`);
}
