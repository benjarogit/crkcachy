import { m, mf, type WizardContext } from "./bridge";
import { styleMuted, styleSuccess, styleWarning, theme } from "./theme";

async function fetchLatestVersion(): Promise<string | null> {
  try {
    const res = await fetch(
      "https://api.github.com/repos/benjarogit/crkcachy/releases/latest",
      { signal: AbortSignal.timeout(5000) },
    );
    if (!res.ok) return null;
    const data = (await res.json()) as { tag_name?: string };
    const tag = data.tag_name ?? "";
    return tag.replace(/^v/i, "") || null;
  } catch {
    return null;
  }
}

export async function printBrandHeader(ctx: WizardContext): Promise<void> {
  const v = ctx.runtime.version;
  const subtitle = m("", ctx, "banner.subtitle");
  const latest = await fetchLatestVersion();

  process.stdout.write("\n");
  process.stdout.write(
    `  ${theme.brand}╔══════════════════════════════════╗${theme.reset}\n`,
  );
  process.stdout.write(
    `  ${theme.brand}║${theme.reset}   ${theme.bold}C R K C A C H Y${theme.reset}   ${theme.brand}║${theme.reset}\n`,
  );
  process.stdout.write(
    `  ${theme.brand}╚══════════════════════════════════╝${theme.reset}\n`,
  );
  process.stdout.write("\n");
  process.stdout.write(`  ${styleMuted(`v${v}  ·  ${subtitle}`)}\n`);

  if (latest && latest !== v) {
    process.stdout.write(
      `\n  ${styleWarning(`↑ ${mf("", ctx, "banner.update_available", `v${v}`, `v${latest}`)}`)}\n`,
    );
    process.stdout.write(
      `  ${styleMuted("    github.com/benjarogit/crkcachy/releases/latest")}\n`,
    );
  } else if (latest) {
    process.stdout.write(
      `\n  ${styleSuccess(`✓ ${mf("", ctx, "banner.version_ok", `v${v}`)}`)}\n`,
    );
  }

  process.stdout.write("\n");
}

export function printMenuDivider(): void {
  const line = "─".repeat(42);
  process.stdout.write(`\n  ${theme.dimColor}${line}${theme.reset}\n\n`);
}
