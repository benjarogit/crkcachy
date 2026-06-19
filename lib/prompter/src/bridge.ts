/**
 * Bash bridge – JSON context + subprocess actions (stdio inherit).
 */
import { spawn, spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

export type WizardMessages = Record<string, string>;

export type WizardContext = {
  messages: WizardMessages;
  runtime: {
    nodeOk: boolean;
    glowOk: boolean;
    nodeVersion: string;
    version: string;
  };
  assess: {
    systemReady: boolean;
    recommended: number;
    ok: number;
    fail: number;
    hint: string;
    score: string;
    issues: string[];
  };
};

export type ToolListItem = { slug: string; label: string; name: string };

export type PreflightState = {
  requiredFail: number;
  recommendedFail: number;
  skipLegal: boolean;
};

export class BridgeError extends Error {
  readonly name = "BridgeError";
}

export function bridgeScript(root: string): string {
  return join(root, "lib/wizard-bridge.sh");
}

function runBridgeSync(root: string, args: string[]): string {
  const script = bridgeScript(root);
  if (!existsSync(script)) {
    throw new BridgeError(`bridge missing: ${script}`);
  }
  const result = spawnSync("bash", [script, ...args], {
    cwd: root,
    encoding: "utf-8",
    env: { ...process.env, CRKCACHY_ROOT: root },
  });
  if (result.status !== 0) {
    const err = (result.stderr || result.stdout || "").trim();
    throw new BridgeError(err || `bridge ${args[0]} failed (${result.status})`);
  }
  return (result.stdout || "").trim();
}

function parseJson<T>(raw: string): T {
  try {
    return JSON.parse(raw) as T;
  } catch {
    throw new BridgeError("bridge returned invalid JSON");
  }
}

export async function loadContext(root: string): Promise<WizardContext> {
  return parseJson(runBridgeSync(root, ["context"]));
}

export function installGlow(root: string, mode: "auto" | "manual"): boolean {
  const result = spawnSync("bash", [bridgeScript(root), "install-glow", mode], {
    cwd: root,
    encoding: "utf-8",
    env: { ...process.env, CRKCACHY_ROOT: root },
    stdio: ["inherit", "inherit", "inherit"],
  });
  return result.status === 0;
}

export function loadPreflightState(root: string): PreflightState {
  return parseJson(runBridgeSync(root, ["preflight-state"]));
}

export function preflightFixRecommended(root: string): void {
  runBridgeSync(root, ["preflight-fix-recommended"]);
}

export function legalAccept(root: string): void {
  runBridgeSync(root, ["legal-accept"]);
}

export function announceChoice(root: string, choice?: string): void {
  runBridgeSync(root, ["announce-choice", choice ?? ""]);
}

export function loadToolsList(root: string): ToolListItem[] {
  return parseJson(runBridgeSync(root, ["tools-list"]));
}

export function bridgeRunInteractive(root: string, ...args: string[]): Promise<number> {
  return new Promise((resolve, reject) => {
    const child = spawn("bash", [bridgeScript(root), ...args], {
      cwd: root,
      env: { ...process.env, CRKCACHY_ROOT: root },
      stdio: "inherit",
    });
    child.on("error", reject);
    child.on("close", (code) => resolve(code ?? 1));
  });
}

export function toolDispatch(root: string, slug: string, action: string): Promise<number> {
  return bridgeRunInteractive(root, "tool-dispatch", slug, action);
}

export function m(root: string, ctx: WizardContext, key: string): string {
  return ctx.messages[key] ?? key;
}

export function mf(root: string, ctx: WizardContext, key: string, ...args: string[]): string {
  const template = m(root, ctx, key);
  let i = 0;
  return template.replace(/%s/g, () => args[i++] ?? "");
}
