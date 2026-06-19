/**
 * Clack-backed prompter – CRKCACHY theme (OpenClaw-style styling).
 */
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
  type Option,
} from "@clack/prompts";
import { styleHint, styleMessage, styleTitle, theme } from "./theme";

export class WizardCancelledError extends Error {
  readonly name = "WizardCancelledError";
}

function guardCancel<T>(value: T | symbol, cancelledLabel = "Abgebrochen."): T {
  if (isCancel(value)) {
    cancel(styleTitle(cancelledLabel));
    throw new WizardCancelledError();
  }
  return value;
}

export type SelectOption = { value: string; label: string; hint?: string };

export type CrkcachyPrompter = {
  intro: (title: string) => Promise<void>;
  outro: (message: string) => Promise<void>;
  note: (message: string, title?: string) => Promise<void>;
  select: (params: {
    message: string;
    options: SelectOption[];
    initialValue?: string;
  }) => Promise<string>;
  autocomplete: (params: {
    message: string;
    options: SelectOption[];
    initialValue?: string;
    placeholder?: string;
  }) => Promise<string>;
  confirm: (message: string, initialValue?: boolean) => Promise<boolean>;
  spin: (label: string, run: () => Promise<void>) => Promise<void>;
};

function toClackOptions(options: SelectOption[]): Option<string>[] {
  return options.map((opt) => {
    const base: Option<string> = { value: opt.value, label: opt.label };
    if (opt.hint) {
      return { ...base, hint: opt.hint };
    }
    return base;
  });
}

export function createCrkcachyPrompter(): CrkcachyPrompter {
  return {
    intro: async (title) => {
      intro(styleTitle(title));
    },
    outro: async (message) => {
      outro(styleSuccess(message));
    },
    note: async (message, title) => {
      note(message, title ? styleTitle(title) : undefined);
    },
    select: async ({ message, options, initialValue }) => {
      return guardCancel(
        await select({
          message: styleMessage(message),
          options: toClackOptions(options),
          initialValue,
        }),
      );
    },
    autocomplete: async ({ message, options, initialValue, placeholder }) => {
      return guardCancel(
        await autocomplete({
          message: styleMessage(message),
          options: toClackOptions(options),
          initialValue,
          placeholder: placeholder ? styleHint(placeholder) : undefined,
        }),
      );
    },
    confirm: async (message, initialValue = false) => {
      return guardCancel(
        await confirm({
          message: styleMessage(message),
          initialValue,
        }),
      );
    },
    spin: async (label, run) => {
      const spin = spinner();
      spin.start(`${theme.brand}${label}${theme.reset}`);
      try {
        await run();
        spin.stop(styleSuccess(label));
      } catch (err) {
        spin.stop(`${theme.error}Fehler${theme.reset}`);
        throw err;
      }
    },
  };
}

export function restoreTerminalGap(): void {
  process.stdout.write("\n");
}
