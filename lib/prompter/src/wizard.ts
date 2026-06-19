/**
 * CRKCACHY install wizard – OpenClaw-style @clack/prompts (full flow in TypeScript).
 */
import { existsSync } from "node:fs";
import { join } from "node:path";
import {
  announceChoice,
  bridgeRunInteractive,
  installGlow,
  legalAccept,
  loadContext,
  loadPreflightState,
  loadToolsList,
  markDepsHint,
  mf,
  m,
  preflightFixRecommended,
  toolDispatch,
  type WizardContext,
  type ToolListItem,
} from "./bridge";
import { printBrandHeader, printMenuDivider } from "./brand";
import {
  createCrkcachyPrompter,
  restoreTerminalGap,
  WizardCancelledError,
} from "./prompter";
import {
  colorizeStatusLines,
  iconOk,
  iconStep,
  iconWarn,
  styleHint,
  styleInfo,
  styleLabel,
  styleMuted,
  styleSuccess,
  styleWarning,
} from "./theme";

function parseArgs(argv: string[]): { root: string; lang?: string } {
  let root = process.env.CRKCACHY_ROOT ?? "";
  let lang = process.env.CRKCACHY_LANG;

  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--root" && argv[i + 1]) {
      root = argv[++i];
    } else if (arg === "--lang" && argv[i + 1]) {
      lang = argv[++i];
    } else if (arg.startsWith("--lang=")) {
      lang = arg.slice("--lang=".length);
    }
  }

  if (!root) {
    root = join(__dirname, "..", "..");
  }

  if (lang) {
    process.env.CRKCACHY_LANG = lang;
  }

  return { root, lang };
}

function hasInteractiveTty(): boolean {
  if (process.stdin.isTTY && process.stdout.isTTY) return true;
  try {
    return existsSync("/dev/tty");
  } catch {
    return false;
  }
}

function recommendedHint(ctx: WizardContext): string {
  switch (ctx.assess.recommended) {
    case 3:
      return m("", ctx, "wizard.hint_ready");
    case 2:
      return m("", ctx, "wizard.hint_fix");
    default:
      return m("", ctx, "wizard.hint_full");
  }
}

function buildMenuOptions(ctx: WizardContext): { value: string; label: string; hint?: string }[] {
  const badge = m("", ctx, "ui.badge_recommended");
  const rec = String(ctx.assess.recommended);
  const options: { value: string; label: string; hint?: string }[] = [];

  const addOpt = (n: number) => {
    const label = m("", ctx, `wizard.opt${n}`);
    const isRec = String(n) === rec;
    const styledLabel = isRec
      ? `${iconStep()} ${styleSuccess(badge)}  ${styleLabel(label)}`
      : n === 5
        ? `${styleWarning("○")} ${styleLabel(label)}`
        : styleLabel(label);

    options.push({
      value: String(n),
      label: styledLabel,
      hint: isRec ? styleHint(recommendedHint(ctx)) : undefined,
    });
  };

  addOpt(ctx.assess.recommended);
  for (const n of [1, 2, 3]) {
    if (String(n) !== rec) addOpt(n);
  }
  if (ctx.assess.recommended !== 4) {
    addOpt(4);
  }
  addOpt(5);
  return options;
}

function buildStyledStatusNote(ctx: WizardContext): string {
  if (ctx.assess.systemReady) {
    const lines: string[] = [
      `${iconOk()} ${styleSuccess(ctx.assess.hint)}`,
    ];

    if (!ctx.runtime.depsHintShown) {
      lines.push("");
      lines.push(styleInfo(m("", ctx, "runtime.deps_cleanup").split("\n")[0] ?? ""));
      const depsBody = m("", ctx, "runtime.deps_cleanup")
        .split("\n")
        .slice(1)
        .join("\n");
      if (depsBody.trim()) {
        lines.push(colorizeStatusLines(depsBody));
      }
      lines.push("");
      lines.push(styleMuted(m("", ctx, "runtime.deps_cleanup_short")));
    }

    return lines.join("\n");
  }

  const lines = [
    `${iconWarn()} ${styleWarning(mf("", ctx, "wizard.status_fix", ctx.assess.score))}`,
    "",
  ];

  if (ctx.assess.issues.length > 0) {
    lines.push(styleMuted("Offene Punkte:"));
    for (const issue of ctx.assess.issues) {
      lines.push(`  ${iconWarn()} ${styleMuted(issue)}`);
    }
  }

  lines.push("");
  lines.push(styleHint(recommendedHint(ctx)));

  return lines.join("\n");
}

async function ensureGlowRuntime(root: string, ctx: WizardContext, p: ReturnType<typeof createCrkcachyPrompter>): Promise<void> {
  if (ctx.runtime.glowOk) return;

  await p.note(
    `${m("", ctx, "runtime.bootstrap_body")}\n\n${m("", ctx, "runtime.bootstrap_hint")}`,
    m("", ctx, "runtime.bootstrap_title"),
  );

  while (true) {
    const pick = await p.select({
      message: m("", ctx, "glow.pick_title"),
      options: [
        { value: "auto", label: m("", ctx, "glow.opt_auto") },
        { value: "manual", label: m("", ctx, "glow.opt_manual") },
      ],
      initialValue: "auto",
    });

    restoreTerminalGap();
    if (pick === "auto") {
      await p.spin(m("", ctx, "glow.password_hint"), async () => {
        if (!installGlow(root, "auto")) {
          throw new Error(m("", ctx, "glow.install_failed"));
        }
      });
    } else {
      installGlow(root, "manual");
      await p.note(
        `${m("", ctx, "glow.manual_steps_intro")}\n\n${m("", ctx, "pkg.explain.footer")}`,
        m("", ctx, "glow.missing_title"),
      );
    }

    const refreshed = await loadContext(root);
    if (refreshed.runtime.glowOk) {
      await p.note(m("", ctx, "glow.installed"));
      return;
    }
    await p.note(m("", ctx, "glow.still_missing"));
  }
}

async function runLegalGate(root: string, ctx: WizardContext, p: ReturnType<typeof createCrkcachyPrompter>): Promise<void> {
  const steps = [
    { title: m("", ctx, "legal.step1_title"), body: m("", ctx, "legal.step1_body") },
    { title: m("", ctx, "legal.step2_title"), body: m("", ctx, "legal.step2_body") },
    { title: m("", ctx, "legal.step3_title"), body: m("", ctx, "legal.step3_body") },
    { title: m("", ctx, "legal.step4_title"), body: m("", ctx, "legal.step4_body") },
  ];

  for (const step of steps) {
    await p.note(step.body, step.title);
  }

  await p.note(m("", ctx, "install.legal_summary"));
  const ok = await p.confirm(m("", ctx, "ui.legal_confirm"), false);
  if (!ok) {
    throw new Error(m("", ctx, "runtime.legal_abort"));
  }
  legalAccept(root);
}

async function runPreflightGates(root: string, ctx: WizardContext, p: ReturnType<typeof createCrkcachyPrompter>): Promise<void> {
  const state = loadPreflightState(root);

  if (state.recommendedFail > 0 && state.requiredFail === 0) {
    const fix = await p.confirm(m("", ctx, "runtime.fix_recommended"), false);
    if (fix) {
      restoreTerminalGap();
      await bridgeRunInteractive(root, "preflight-fix-recommended");
    }
  }

  const after = loadPreflightState(root);
  if (after.requiredFail > 0) {
    throw new Error(m("", ctx, "runtime.cannot_continue"));
  }

  if (!state.skipLegal) {
    await runLegalGate(root, ctx, p);
  }
}

async function pickTool(
  root: string,
  ctx: WizardContext,
  p: ReturnType<typeof createCrkcachyPrompter>,
  uninstall = false,
): Promise<string | null> {
  const tools = loadToolsList(root);
  if (tools.length === 0) {
    await p.note(m("", ctx, "tools.none"));
    return null;
  }

  const options: { value: string; label: string }[] = tools.map((t: ToolListItem) => ({
    value: t.slug,
    label: t.label,
  }));

  if (!uninstall) {
    options.push({ value: "__refresh__", label: m("", ctx, "tools.hub_refresh") });
  }
  options.push({ value: "", label: m("", ctx, "action.opt_back") });

  const hint = uninstall
    ? m("", ctx, "wizard.choose_hint")
    : m("", ctx, "tools.hub_pick_hint");

  const slug = await p.autocomplete({
    message: hint,
    placeholder: m("", ctx, "tools.hub_search_hint"),
    options,
  });

  if (!slug || slug === "") return null;
  if (slug === "__refresh__") {
    restoreTerminalGap();
    await bridgeRunInteractive(root, "tools-refresh");
    return pickTool(root, await loadContext(root), p, uninstall);
  }
  return slug;
}

async function pickToolAction(
  root: string,
  ctx: WizardContext,
  p: ReturnType<typeof createCrkcachyPrompter>,
  toolName: string,
): Promise<string | null> {
  const menuMsg = mf("", ctx, "action.menu_teaser", toolName);
  await p.note(menuMsg, m("", ctx, "action.menu_title"));

  const slug = await p.select({
    message: m("", ctx, "action.menu_hint"),
    options: [
      { value: "install", label: m("", ctx, "action.opt_install") },
      { value: "uninstall", label: m("", ctx, "action.opt_uninstall") },
      { value: "check", label: m("", ctx, "action.opt_check") },
      { value: "reset", label: m("", ctx, "action.opt_reset") },
      { value: "back", label: m("", ctx, "action.opt_back") },
    ],
    initialValue: "install",
  });

  return slug === "back" ? null : slug;
}

async function runGameFlow(root: string, ctx: WizardContext, p: ReturnType<typeof createCrkcachyPrompter>): Promise<boolean> {
  restoreTerminalGap();
  const readyCode = await bridgeRunInteractive(root, "assess-ensure-ready");
  if (readyCode !== 0) return false;

  const slug = await pickTool(root, ctx, p);
  if (!slug) return false;

  const tools = loadToolsList(root);
  const tool = tools.find((t) => t.slug === slug);
  const toolName = tool?.name ?? slug;

  const action = await pickToolAction(root, ctx, p, toolName);
  if (!action) return false;

  restoreTerminalGap();
  const code = await toolDispatch(root, slug, action);
  return code === 0;
}

async function runUninstallFlow(root: string, ctx: WizardContext, p: ReturnType<typeof createCrkcachyPrompter>): Promise<boolean> {
  const slug = await pickTool(root, ctx, p, true);
  if (!slug) return false;
  restoreTerminalGap();
  const code = await toolDispatch(root, slug, "uninstall");
  return code === 0;
}

async function afterInstallMenu(root: string, p: ReturnType<typeof createCrkcachyPrompter>): Promise<"menu" | "exit"> {
  const ctx = await loadContext(root);
  const pick = await p.select({
    message: m("", ctx, "install.after_title"),
    options: [
      { value: "menu", label: m("", ctx, "install.after_menu") },
      { value: "exit", label: m("", ctx, "install.after_exit") },
    ],
  });
  return pick === "exit" ? "exit" : "menu";
}

async function afterPcFixMenu(root: string, p: ReturnType<typeof createCrkcachyPrompter>): Promise<"install" | "menu" | "exit"> {
  const ctx = await loadContext(root);
  const pick = await p.select({
    message: m("", ctx, "assess.after_pc_title"),
    options: [
      { value: "install", label: m("", ctx, "assess.after_pc_install") },
      { value: "menu", label: m("", ctx, "assess.after_pc_menu") },
      { value: "exit", label: m("", ctx, "assess.after_pc_exit") },
    ],
  });
  return pick as "install" | "menu" | "exit";
}

async function afterUninstallMenu(root: string, p: ReturnType<typeof createCrkcachyPrompter>): Promise<"menu" | "install" | "exit"> {
  const ctx = await loadContext(root);
  const pick = await p.select({
    message: m("", ctx, "wizard.after_uninstall_title"),
    options: [
      { value: "menu", label: m("", ctx, "wizard.after_uninstall_menu") },
      { value: "install", label: m("", ctx, "wizard.after_uninstall_install") },
      { value: "exit", label: m("", ctx, "wizard.after_uninstall_exit") },
    ],
  });
  return pick as "menu" | "install" | "exit";
}

async function mainMenuLoop(root: string, p: ReturnType<typeof createCrkcachyPrompter>): Promise<void> {
  let firstScreen = true;

  while (true) {
    const ctx = await loadContext(root);

    if (firstScreen) {
      await printBrandHeader(ctx);
      firstScreen = false;
    } else {
      printMenuDivider();
    }

    await p.note(buildStyledStatusNote(ctx), m("", ctx, "wizard.title"));

    if (!ctx.runtime.depsHintShown && ctx.assess.systemReady) {
      markDepsHint(root);
    }

    const choice = await p.select({
      message: m("", ctx, "wizard.choose_hint"),
      options: buildMenuOptions(ctx),
      initialValue: String(ctx.assess.recommended),
    });

    restoreTerminalGap();
    announceChoice(root, choice);

    switch (choice) {
      case "1": {
        await bridgeRunInteractive(root, "run-pc-fix");
        if (await runGameFlow(root, ctx, p)) {
          const next = await afterInstallMenu(root, p);
          if (next === "exit") {
            await p.outro(m("", ctx, "install.goodbye"));
            return;
          }
        }
        break;
      }
      case "2": {
        await bridgeRunInteractive(root, "run-pc-fix");
        const next = await afterPcFixMenu(root, p);
        if (next === "exit") {
          await p.outro(m("", ctx, "install.goodbye"));
          return;
        }
        if (next === "install" && (await runGameFlow(root, ctx, p))) {
          const after = await afterInstallMenu(root, p);
          if (after === "exit") {
            await p.outro(m("", ctx, "install.goodbye"));
            return;
          }
        }
        break;
      }
      case "3": {
        if (await runGameFlow(root, ctx, p)) {
          const next = await afterInstallMenu(root, p);
          if (next === "exit") {
            await p.outro(m("", ctx, "install.goodbye"));
            return;
          }
        }
        break;
      }
      case "4": {
        restoreTerminalGap();
        await bridgeRunInteractive(root, "print-status");
        restoreTerminalGap();
        break;
      }
      case "5": {
        if (await runUninstallFlow(root, ctx, p)) {
          const next = await afterUninstallMenu(root, p);
          if (next === "exit") return;
          if (next === "install" && (await runGameFlow(root, ctx, p))) {
            const after = await afterInstallMenu(root, p);
            if (after === "exit") {
              await p.outro(m("", ctx, "install.goodbye"));
              return;
            }
          }
        }
        break;
      }
      default:
        break;
    }
  }
}

async function runWizard(root: string): Promise<void> {
  const wizardJs = join(root, "lib/prompter/dist/wizard.js");
  if (!existsSync(wizardJs)) {
    process.stderr.write(`wizard missing: ${wizardJs}\n`);
    process.exit(2);
  }

  if (!hasInteractiveTty()) {
    const ctx = await loadContext(root);
    process.stderr.write(`${m("", ctx, "node.no_tty")}\n`);
    process.exit(1);
  }

  const p = createCrkcachyPrompter();
  let ctx = await loadContext(root);

  if (!ctx.runtime.nodeOk) {
    process.stderr.write("Node.js 18+ required to run wizard.\n");
    process.exit(1);
  }

  try {
    await ensureGlowRuntime(root, ctx, p);
    ctx = await loadContext(root);
    await runPreflightGates(root, ctx, p);
    await mainMenuLoop(root, p);
  } catch (err) {
    if (err instanceof WizardCancelledError) {
      process.exit(1);
    }
    const msg = err instanceof Error ? err.message : String(err);
    process.stderr.write(`${msg}\n`);
    process.exit(1);
  }
}

const { root } = parseArgs(process.argv);
runWizard(root);
