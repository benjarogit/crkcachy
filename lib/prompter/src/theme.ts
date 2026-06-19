/**
 * CRKCACHY terminal theme – matches lib/cui.sh ANSI-256 tokens.
 */
export const palette = {
  brand: 99,
  success: 76,
  warning: 214,
  error: 196,
  info: 117,
  muted: 245,
  dim: 238,
  step: 147,
} as const;

const R = "\x1b[0m";
const B = "\x1b[1m";
const D = "\x1b[2m";

function fg(n: number): string {
  return `\x1b[38;5;${n}m`;
}

export const theme = {
  reset: R,
  bold: B,
  dim: D,
  brand: fg(palette.brand),
  success: fg(palette.success),
  warning: fg(palette.warning),
  error: fg(palette.error),
  info: fg(palette.info),
  muted: fg(palette.muted),
  dimColor: fg(palette.dim),
  step: fg(palette.step),
};

export function styleTitle(text: string): string {
  return `${theme.brand}${B}${text}${R}`;
}

export function styleMessage(text: string): string {
  return `${theme.brand}${text}${R}`;
}

export function styleHint(text: string): string {
  return `${theme.muted}${D}${text}${R}`;
}

export function styleSuccess(text: string): string {
  return `${theme.success}${text}${R}`;
}

export function styleWarning(text: string): string {
  return `${theme.warning}${text}${R}`;
}

export function styleMuted(text: string): string {
  return `${theme.muted}${text}${R}`;
}

export function styleLabel(text: string): string {
  return `${B}${text}${R}`;
}

export function styleInfo(text: string): string {
  return `${theme.info}${text}${R}`;
}

export function iconOk(): string {
  return `${theme.success}✓${R}`;
}

export function iconWarn(): string {
  return `${theme.warning}○${R}`;
}

export function iconFail(): string {
  return `${theme.error}✗${R}`;
}

export function iconStep(): string {
  return `${theme.step}◆${R}`;
}

/** Colorize ✓ / ✗ / ○ prefixes in multiline i18n text. */
export function colorizeStatusLines(body: string): string {
  return body
    .split("\n")
    .map((line) => {
      const trimmed = line.trimStart();
      if (trimmed.startsWith("✓")) {
        return line.replace("✓", iconOk());
      }
      if (trimmed.startsWith("✗")) {
        return line.replace("✗", iconFail());
      }
      if (trimmed.startsWith("○")) {
        return line.replace("○", iconWarn());
      }
      return line;
    })
    .join("\n");
}
