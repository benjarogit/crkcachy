/**
 * CRKCACHY prompter CLI – @clack/prompts (OpenClaw-style).
 * Bash: node dist/cli.js <command> --stdin  (JSON body on stdin)
 */
import { readFileSync } from "node:fs";
import {
  autocomplete,
  cancel,
  confirm,
  intro,
  isCancel,
  note,
  outro,
  select,
  spinner,
  text,
  type Option,
} from "@clack/prompts";
import { spawnSync } from "node:child_process";

type SelectOption = { value: string; label: string; hint?: string };

type PromptPayload = {
  message?: string;
  title?: string;
  options?: SelectOption[];
  initialValue?: string;
  initialValues?: string[];
  placeholder?: string;
  defaultValue?: string;
  initialValueConfirm?: boolean;
  command?: string;
};

function readPayload(): PromptPayload {
  const fileIdx = process.argv.indexOf("--file");
  if (fileIdx >= 0 && process.argv[fileIdx + 1]) {
    const raw = readFileSync(process.argv[fileIdx + 1], "utf-8").trim();
    if (!raw) return {};
    return JSON.parse(raw) as PromptPayload;
  }

  if (process.argv.includes("--stdin")) {
    const raw = readFileSync(0, "utf-8").trim();
    if (!raw) return {};
    return JSON.parse(raw) as PromptPayload;
  }

  return {};
}

function guard<T>(value: T | symbol): T {
  if (isCancel(value)) {
    cancel("Abgebrochen.");
    process.stdout.write(JSON.stringify({ ok: false, cancelled: true }));
    process.exit(1);
  }
  return value;
}

function writeOk(value: unknown): void {
  process.stdout.write(JSON.stringify({ ok: true, value }));
}

function toClackOptions(options: SelectOption[]): Option<string>[] {
  return options.map((opt) => {
    const base: Option<string> = { value: opt.value, label: opt.label };
    if (opt.hint) {
      return { ...base, hint: opt.hint };
    }
    return base;
  });
}

async function main(): Promise<void> {
  const cmd = process.argv[2];
  if (!cmd) {
    process.stderr.write("usage: cli.js <command> [--file path.json | --stdin]\n");
    process.exit(2);
  }

  const data = readPayload();

  switch (cmd) {
    case "intro":
      intro(data.message ?? "");
      break;

    case "outro":
      outro(data.message ?? "");
      break;

    case "note":
      note(data.message ?? "", data.title);
      break;

    case "select": {
      const options = data.options ?? [];
      const val = guard(
        await select({
          message: data.message ?? "",
          options: toClackOptions(options),
          initialValue: data.initialValue,
        }),
      );
      writeOk(val);
      break;
    }

    case "autocomplete": {
      const options = data.options ?? [];
      const val = guard(
        await autocomplete({
          message: data.message ?? "",
          options: toClackOptions(options),
          initialValue: data.initialValue,
        }),
      );
      writeOk(val);
      break;
    }

    case "confirm": {
      const val = guard(
        await confirm({
          message: data.message ?? "",
          initialValue: data.initialValueConfirm ?? false,
        }),
      );
      writeOk(val);
      break;
    }

    case "text": {
      const val = guard(
        await text({
          message: data.message ?? "",
          placeholder: data.placeholder,
          defaultValue: data.defaultValue,
        }),
      );
      writeOk(val ?? "");
      break;
    }

    case "continue": {
      const label = data.message ?? "Weiter";
      const val = guard(
        await select({
          message: label,
          options: [{ value: "ok", label: data.title ?? "Weiter" }],
        }),
      );
      writeOk(val);
      break;
    }

    case "spin": {
      const spin = spinner();
      spin.start(data.message ?? "");
      const shellCmd = data.command ?? "true";
      const result = spawnSync(shellCmd, {
        shell: true,
        stdio: "inherit",
        env: process.env,
      });
      if (result.status === 0) {
        spin.stop(data.title ?? "");
      } else {
        spin.stop("Fehler");
        process.exit(result.status ?? 1);
      }
      writeOk(true);
      break;
    }

    default:
      process.stderr.write(`unknown command: ${cmd}\n`);
      process.exit(2);
  }
}

main().catch((err: unknown) => {
  process.stderr.write(String(err));
  process.exit(1);
});
