#!/usr/bin/env node
"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// node_modules/sisteransi/src/index.js
var require_src = __commonJS({
  "node_modules/sisteransi/src/index.js"(exports2, module2) {
    "use strict";
    var ESC2 = "\x1B";
    var CSI2 = `${ESC2}[`;
    var beep = "\x07";
    var cursor3 = {
      to(x, y) {
        if (!y) return `${CSI2}${x + 1}G`;
        return `${CSI2}${y + 1};${x + 1}H`;
      },
      move(x, y) {
        let ret = "";
        if (x < 0) ret += `${CSI2}${-x}D`;
        else if (x > 0) ret += `${CSI2}${x}C`;
        if (y < 0) ret += `${CSI2}${-y}A`;
        else if (y > 0) ret += `${CSI2}${y}B`;
        return ret;
      },
      up: (count = 1) => `${CSI2}${count}A`,
      down: (count = 1) => `${CSI2}${count}B`,
      forward: (count = 1) => `${CSI2}${count}C`,
      backward: (count = 1) => `${CSI2}${count}D`,
      nextLine: (count = 1) => `${CSI2}E`.repeat(count),
      prevLine: (count = 1) => `${CSI2}F`.repeat(count),
      left: `${CSI2}G`,
      hide: `${CSI2}?25l`,
      show: `${CSI2}?25h`,
      save: `${ESC2}7`,
      restore: `${ESC2}8`
    };
    var scroll = {
      up: (count = 1) => `${CSI2}S`.repeat(count),
      down: (count = 1) => `${CSI2}T`.repeat(count)
    };
    var erase3 = {
      screen: `${CSI2}2J`,
      up: (count = 1) => `${CSI2}1J`.repeat(count),
      down: (count = 1) => `${CSI2}J`.repeat(count),
      line: `${CSI2}2K`,
      lineEnd: `${CSI2}K`,
      lineStart: `${CSI2}1K`,
      lines(count) {
        let clear = "";
        for (let i2 = 0; i2 < count; i2++)
          clear += this.line + (i2 < count - 1 ? cursor3.up() : "");
        if (count)
          clear += cursor3.left;
        return clear;
      }
    };
    module2.exports = { cursor: cursor3, scroll, erase: erase3, beep };
  }
});

// src/wizard.ts
var import_node_fs2 = require("node:fs");
var import_node_path2 = require("node:path");

// src/bridge.ts
var import_node_child_process = require("node:child_process");
var import_node_fs = require("node:fs");
var import_node_path = require("node:path");
var BridgeError = class extends Error {
  name = "BridgeError";
};
function bridgeScript(root2) {
  return (0, import_node_path.join)(root2, "lib/wizard-bridge.sh");
}
function runBridgeSync(root2, args) {
  const script = bridgeScript(root2);
  if (!(0, import_node_fs.existsSync)(script)) {
    throw new BridgeError(`bridge missing: ${script}`);
  }
  const result = (0, import_node_child_process.spawnSync)("bash", [script, ...args], {
    cwd: root2,
    encoding: "utf-8",
    env: { ...process.env, CRKCACHY_ROOT: root2 }
  });
  if (result.status !== 0) {
    const err = (result.stderr || result.stdout || "").trim();
    throw new BridgeError(err || `bridge ${args[0]} failed (${result.status})`);
  }
  return (result.stdout || "").trim();
}
function parseJson(raw) {
  try {
    return JSON.parse(raw);
  } catch {
    throw new BridgeError("bridge returned invalid JSON");
  }
}
async function loadContext(root2) {
  return parseJson(runBridgeSync(root2, ["context"]));
}
function installGlow(root2, mode) {
  const result = (0, import_node_child_process.spawnSync)("bash", [bridgeScript(root2), "install-glow", mode], {
    cwd: root2,
    encoding: "utf-8",
    env: { ...process.env, CRKCACHY_ROOT: root2 },
    stdio: ["inherit", "inherit", "inherit"]
  });
  return result.status === 0;
}
function loadPreflightState(root2) {
  return parseJson(runBridgeSync(root2, ["preflight-state"]));
}
function legalAccept(root2) {
  runBridgeSync(root2, ["legal-accept"]);
}
function announceChoice(root2, choice) {
  runBridgeSync(root2, ["announce-choice", choice ?? ""]);
}
function loadToolsList(root2) {
  return parseJson(runBridgeSync(root2, ["tools-list"]));
}
function bridgeRunInteractive(root2, ...args) {
  return new Promise((resolve, reject) => {
    const child = (0, import_node_child_process.spawn)("bash", [bridgeScript(root2), ...args], {
      cwd: root2,
      env: { ...process.env, CRKCACHY_ROOT: root2 },
      stdio: "inherit"
    });
    child.on("error", reject);
    child.on("close", (code) => resolve(code ?? 1));
  });
}
function toolDispatch(root2, slug, action) {
  return bridgeRunInteractive(root2, "tool-dispatch", slug, action);
}
function m(root2, ctx, key) {
  return ctx.messages[key] ?? key;
}
function mf(root2, ctx, key, ...args) {
  const template = m(root2, ctx, key);
  let i2 = 0;
  return template.replace(/%s/g, () => args[i2++] ?? "");
}

// src/theme.ts
var palette = {
  brand: 99,
  success: 76,
  warning: 214,
  error: 196,
  info: 117,
  muted: 245,
  dim: 238,
  step: 147
};
var R = "\x1B[0m";
var B = "\x1B[1m";
var D = "\x1B[2m";
function fg(n2) {
  return `\x1B[38;5;${n2}m`;
}
var theme = {
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
  step: fg(palette.step)
};
function styleTitle(text) {
  return `${theme.brand}${B}${text}${R}`;
}
function styleMessage(text) {
  return `${theme.brand}${text}${R}`;
}
function styleHint(text) {
  return `${theme.muted}${D}${text}${R}`;
}
function styleSuccess(text) {
  return `${theme.success}${text}${R}`;
}
function styleWarning(text) {
  return `${theme.warning}${text}${R}`;
}
function styleMuted(text) {
  return `${theme.muted}${text}${R}`;
}
function styleLabel(text) {
  return `${B}${text}${R}`;
}
function iconOk() {
  return `${theme.success}\u2713${R}`;
}
function iconWarn() {
  return `${theme.warning}\u25CB${R}`;
}
function iconStep() {
  return `${theme.step}\u25C6${R}`;
}

// src/brand.ts
async function fetchLatestVersion() {
  try {
    const res = await fetch(
      "https://api.github.com/repos/benjarogit/crkcachy/releases/latest",
      { signal: AbortSignal.timeout(5e3) }
    );
    if (!res.ok) return null;
    const data = await res.json();
    const tag = data.tag_name ?? "";
    return tag.replace(/^v/i, "") || null;
  } catch {
    return null;
  }
}
async function printBrandHeader(ctx) {
  const v = ctx.runtime.version;
  const subtitle = m("", ctx, "banner.subtitle");
  const latest = await fetchLatestVersion();
  process.stdout.write("\n");
  process.stdout.write(
    `  ${theme.brand}\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557${theme.reset}
`
  );
  process.stdout.write(
    `  ${theme.brand}\u2551${theme.reset}   ${theme.bold}C R K C A C H Y${theme.reset}   ${theme.brand}\u2551${theme.reset}
`
  );
  process.stdout.write(
    `  ${theme.brand}\u255A\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255D${theme.reset}
`
  );
  process.stdout.write("\n");
  process.stdout.write(`  ${styleMuted(`v${v}  \xB7  ${subtitle}`)}
`);
  if (latest && latest !== v) {
    process.stdout.write(
      `
  ${styleWarning(`\u2191 ${mf("", ctx, "banner.update_available", `v${v}`, `v${latest}`)}`)}
`
    );
    process.stdout.write(
      `  ${styleMuted("    github.com/benjarogit/crkcachy/releases/latest")}
`
    );
    process.stdout.write("\n");
  }
}
function printMenuDivider() {
  const line = "\u2500".repeat(42);
  process.stdout.write(`
  ${theme.dimColor}${line}${theme.reset}

`);
}

// node_modules/@clack/core/dist/index.mjs
var import_node_util = require("node:util");
var import_node_process = require("node:process");
var l = __toESM(require("node:readline"), 1);
var import_node_readline = __toESM(require("node:readline"), 1);

// node_modules/fast-string-truncated-width/dist/utils.js
var getCodePointsLength = /* @__PURE__ */ (() => {
  const SURROGATE_PAIR_RE = /[\uD800-\uDBFF][\uDC00-\uDFFF]/g;
  return (input) => {
    let surrogatePairsNr = 0;
    SURROGATE_PAIR_RE.lastIndex = 0;
    while (SURROGATE_PAIR_RE.test(input)) {
      surrogatePairsNr += 1;
    }
    return input.length - surrogatePairsNr;
  };
})();
var isFullWidth = (x) => {
  return x === 12288 || x >= 65281 && x <= 65376 || x >= 65504 && x <= 65510;
};
var isWideNotCJKTNotEmoji = (x) => {
  return x === 8987 || x === 9001 || x >= 12272 && x <= 12287 || x >= 12289 && x <= 12350 || x >= 12441 && x <= 12543 || x >= 12549 && x <= 12591 || x >= 12593 && x <= 12686 || x >= 12688 && x <= 12771 || x >= 12783 && x <= 12830 || x >= 12832 && x <= 12871 || x >= 12880 && x <= 19903 || x >= 65040 && x <= 65049 || x >= 65072 && x <= 65106 || x >= 65108 && x <= 65126 || x >= 65128 && x <= 65131 || x >= 127488 && x <= 127490 || x >= 127504 && x <= 127547 || x >= 127552 && x <= 127560 || x >= 131072 && x <= 196605 || x >= 196608 && x <= 262141;
};

// node_modules/fast-string-truncated-width/dist/index.js
var ANSI_RE = /[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]|\u001b\]8;[^;]*;.*?(?:\u0007|\u001b\u005c)/y;
var CONTROL_RE = /[\x00-\x08\x0A-\x1F\x7F-\x9F]{1,1000}/y;
var CJKT_WIDE_RE = /(?:(?![\uFF61-\uFF9F\uFF00-\uFFEF])[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}\p{Script=Tangut}]){1,1000}/yu;
var TAB_RE = /\t{1,1000}/y;
var EMOJI_RE = new RegExp("[\\u{1F1E6}-\\u{1F1FF}]{2}|\\u{1F3F4}[\\u{E0061}-\\u{E007A}]{2}[\\u{E0030}-\\u{E0039}\\u{E0061}-\\u{E007A}]{1,3}\\u{E007F}|(?:\\p{Emoji}\\uFE0F\\u20E3?|\\p{Emoji_Modifier_Base}\\p{Emoji_Modifier}?|\\p{Emoji_Presentation})(?:\\u200D(?:\\p{Emoji_Modifier_Base}\\p{Emoji_Modifier}?|\\p{Emoji_Presentation}|\\p{Emoji}\\uFE0F\\u20E3?))*", "yu");
var LATIN_RE = /(?:[\x20-\x7E\xA0-\xFF](?!\uFE0F)){1,1000}/y;
var MODIFIER_RE = new RegExp("\\p{M}+", "gu");
var NO_TRUNCATION = { limit: Infinity, ellipsis: "" };
var getStringTruncatedWidth = (input, truncationOptions = {}, widthOptions = {}) => {
  const LIMIT = truncationOptions.limit ?? Infinity;
  const ELLIPSIS = truncationOptions.ellipsis ?? "";
  const ELLIPSIS_WIDTH = truncationOptions?.ellipsisWidth ?? (ELLIPSIS ? getStringTruncatedWidth(ELLIPSIS, NO_TRUNCATION, widthOptions).width : 0);
  const ANSI_WIDTH = 0;
  const CONTROL_WIDTH = widthOptions.controlWidth ?? 0;
  const TAB_WIDTH = widthOptions.tabWidth ?? 8;
  const EMOJI_WIDTH = widthOptions.emojiWidth ?? 2;
  const FULL_WIDTH_WIDTH = 2;
  const REGULAR_WIDTH = widthOptions.regularWidth ?? 1;
  const WIDE_WIDTH = widthOptions.wideWidth ?? FULL_WIDTH_WIDTH;
  const PARSE_BLOCKS = [
    [LATIN_RE, REGULAR_WIDTH],
    [ANSI_RE, ANSI_WIDTH],
    [CONTROL_RE, CONTROL_WIDTH],
    [TAB_RE, TAB_WIDTH],
    [EMOJI_RE, EMOJI_WIDTH],
    [CJKT_WIDE_RE, WIDE_WIDTH]
  ];
  let indexPrev = 0;
  let index = 0;
  let length = input.length;
  let lengthExtra = 0;
  let truncationEnabled = false;
  let truncationIndex = length;
  let truncationLimit = Math.max(0, LIMIT - ELLIPSIS_WIDTH);
  let unmatchedStart = 0;
  let unmatchedEnd = 0;
  let width = 0;
  let widthExtra = 0;
  outer: while (true) {
    if (unmatchedEnd > unmatchedStart || index >= length && index > indexPrev) {
      const unmatched = input.slice(unmatchedStart, unmatchedEnd) || input.slice(indexPrev, index);
      lengthExtra = 0;
      for (const char of unmatched.replaceAll(MODIFIER_RE, "")) {
        const codePoint = char.codePointAt(0) || 0;
        if (isFullWidth(codePoint)) {
          widthExtra = FULL_WIDTH_WIDTH;
        } else if (isWideNotCJKTNotEmoji(codePoint)) {
          widthExtra = WIDE_WIDTH;
        } else {
          widthExtra = REGULAR_WIDTH;
        }
        if (width + widthExtra > truncationLimit) {
          truncationIndex = Math.min(truncationIndex, Math.max(unmatchedStart, indexPrev) + lengthExtra);
        }
        if (width + widthExtra > LIMIT) {
          truncationEnabled = true;
          break outer;
        }
        lengthExtra += char.length;
        width += widthExtra;
      }
      unmatchedStart = unmatchedEnd = 0;
    }
    if (index >= length) {
      break outer;
    }
    for (let i2 = 0, l2 = PARSE_BLOCKS.length; i2 < l2; i2++) {
      const [BLOCK_RE, BLOCK_WIDTH] = PARSE_BLOCKS[i2];
      BLOCK_RE.lastIndex = index;
      if (BLOCK_RE.test(input)) {
        lengthExtra = BLOCK_RE === CJKT_WIDE_RE ? getCodePointsLength(input.slice(index, BLOCK_RE.lastIndex)) : BLOCK_RE === EMOJI_RE ? 1 : BLOCK_RE.lastIndex - index;
        widthExtra = lengthExtra * BLOCK_WIDTH;
        if (width + widthExtra > truncationLimit) {
          truncationIndex = Math.min(truncationIndex, index + Math.floor((truncationLimit - width) / BLOCK_WIDTH));
        }
        if (width + widthExtra > LIMIT) {
          truncationEnabled = true;
          break outer;
        }
        width += widthExtra;
        unmatchedStart = indexPrev;
        unmatchedEnd = index;
        index = indexPrev = BLOCK_RE.lastIndex;
        continue outer;
      }
    }
    index += 1;
  }
  return {
    width: truncationEnabled ? truncationLimit : width,
    index: truncationEnabled ? truncationIndex : length,
    truncated: truncationEnabled,
    ellipsed: truncationEnabled && LIMIT >= ELLIPSIS_WIDTH
  };
};
var dist_default = getStringTruncatedWidth;

// node_modules/fast-string-width/dist/index.js
var NO_TRUNCATION2 = {
  limit: Infinity,
  ellipsis: "",
  ellipsisWidth: 0
};
var fastStringWidth = (input, options = {}) => {
  return dist_default(input, NO_TRUNCATION2, options).width;
};
var dist_default2 = fastStringWidth;

// node_modules/fast-wrap-ansi/lib/main.js
var ESC = "\x1B";
var CSI = "\x9B";
var END_CODE = 39;
var ANSI_ESCAPE_BELL = "\x07";
var ANSI_CSI = "[";
var ANSI_OSC = "]";
var ANSI_SGR_TERMINATOR = "m";
var ANSI_ESCAPE_LINK = `${ANSI_OSC}8;;`;
var GROUP_REGEX = new RegExp(`(?:\\${ANSI_CSI}(?<code>\\d+)m|\\${ANSI_ESCAPE_LINK}(?<uri>.*)${ANSI_ESCAPE_BELL})`, "y");
var getClosingCode = (openingCode) => {
  if (openingCode >= 30 && openingCode <= 37)
    return 39;
  if (openingCode >= 90 && openingCode <= 97)
    return 39;
  if (openingCode >= 40 && openingCode <= 47)
    return 49;
  if (openingCode >= 100 && openingCode <= 107)
    return 49;
  if (openingCode === 1 || openingCode === 2)
    return 22;
  if (openingCode === 3)
    return 23;
  if (openingCode === 4)
    return 24;
  if (openingCode === 7)
    return 27;
  if (openingCode === 8)
    return 28;
  if (openingCode === 9)
    return 29;
  if (openingCode === 0)
    return 0;
  return void 0;
};
var wrapAnsiCode = (code) => `${ESC}${ANSI_CSI}${code}${ANSI_SGR_TERMINATOR}`;
var wrapAnsiHyperlink = (url) => `${ESC}${ANSI_ESCAPE_LINK}${url}${ANSI_ESCAPE_BELL}`;
var wrapWord = (rows, word, columns) => {
  const characters = word[Symbol.iterator]();
  let isInsideEscape = false;
  let isInsideLinkEscape = false;
  let lastRow = rows.at(-1);
  let visible = lastRow === void 0 ? 0 : dist_default2(lastRow);
  let currentCharacter = characters.next();
  let nextCharacter = characters.next();
  let rawCharacterIndex = 0;
  while (!currentCharacter.done) {
    const character = currentCharacter.value;
    const characterLength = dist_default2(character);
    if (visible + characterLength <= columns) {
      rows[rows.length - 1] += character;
    } else {
      rows.push(character);
      visible = 0;
    }
    if (character === ESC || character === CSI) {
      isInsideEscape = true;
      isInsideLinkEscape = word.startsWith(ANSI_ESCAPE_LINK, rawCharacterIndex + 1);
    }
    if (isInsideEscape) {
      if (isInsideLinkEscape) {
        if (character === ANSI_ESCAPE_BELL) {
          isInsideEscape = false;
          isInsideLinkEscape = false;
        }
      } else if (character === ANSI_SGR_TERMINATOR) {
        isInsideEscape = false;
      }
    } else {
      visible += characterLength;
      if (visible === columns && !nextCharacter.done) {
        rows.push("");
        visible = 0;
      }
    }
    currentCharacter = nextCharacter;
    nextCharacter = characters.next();
    rawCharacterIndex += character.length;
  }
  lastRow = rows.at(-1);
  if (!visible && lastRow !== void 0 && lastRow.length && rows.length > 1) {
    rows[rows.length - 2] += rows.pop();
  }
};
var stringVisibleTrimSpacesRight = (string) => {
  const words = string.split(" ");
  let last = words.length;
  while (last) {
    if (dist_default2(words[last - 1])) {
      break;
    }
    last--;
  }
  if (last === words.length) {
    return string;
  }
  return words.slice(0, last).join(" ") + words.slice(last).join("");
};
var exec = (string, columns, options = {}) => {
  if (options.trim !== false && string.trim() === "") {
    return "";
  }
  let returnValue = "";
  let escapeCode;
  let escapeUrl;
  const words = string.split(" ");
  let rows = [""];
  let rowLength = 0;
  for (let index = 0; index < words.length; index++) {
    const word = words[index];
    if (options.trim !== false) {
      const row = rows.at(-1) ?? "";
      const trimmed = row.trimStart();
      if (row.length !== trimmed.length) {
        rows[rows.length - 1] = trimmed;
        rowLength = dist_default2(trimmed);
      }
    }
    if (index !== 0) {
      if (rowLength >= columns && (options.wordWrap === false || options.trim === false)) {
        rows.push("");
        rowLength = 0;
      }
      if (rowLength || options.trim === false) {
        rows[rows.length - 1] += " ";
        rowLength++;
      }
    }
    const wordLength = dist_default2(word);
    if (options.hard && wordLength > columns) {
      const remainingColumns = columns - rowLength;
      const breaksStartingThisLine = 1 + Math.floor((wordLength - remainingColumns - 1) / columns);
      const breaksStartingNextLine = Math.floor((wordLength - 1) / columns);
      if (breaksStartingNextLine < breaksStartingThisLine) {
        rows.push("");
      }
      wrapWord(rows, word, columns);
      rowLength = dist_default2(rows.at(-1) ?? "");
      continue;
    }
    if (rowLength + wordLength > columns && rowLength && wordLength) {
      if (options.wordWrap === false && rowLength < columns) {
        wrapWord(rows, word, columns);
        rowLength = dist_default2(rows.at(-1) ?? "");
        continue;
      }
      rows.push("");
      rowLength = 0;
    }
    if (rowLength + wordLength > columns && options.wordWrap === false) {
      wrapWord(rows, word, columns);
      rowLength = dist_default2(rows.at(-1) ?? "");
      continue;
    }
    rows[rows.length - 1] += word;
    rowLength += wordLength;
  }
  if (options.trim !== false) {
    rows = rows.map((row) => stringVisibleTrimSpacesRight(row));
  }
  const preString = rows.join("\n");
  let inSurrogate = false;
  for (let i2 = 0; i2 < preString.length; i2++) {
    const character = preString[i2];
    returnValue += character;
    if (!inSurrogate) {
      inSurrogate = character >= "\uD800" && character <= "\uDBFF";
      if (inSurrogate) {
        continue;
      }
    } else {
      inSurrogate = false;
    }
    if (character === ESC || character === CSI) {
      GROUP_REGEX.lastIndex = i2 + 1;
      const groupsResult = GROUP_REGEX.exec(preString);
      const groups = groupsResult?.groups;
      if (groups?.code !== void 0) {
        const code = Number.parseFloat(groups.code);
        escapeCode = code === END_CODE ? void 0 : code;
      } else if (groups?.uri !== void 0) {
        escapeUrl = groups.uri.length === 0 ? void 0 : groups.uri;
      }
    }
    if (preString[i2 + 1] === "\n") {
      if (escapeUrl) {
        returnValue += wrapAnsiHyperlink("");
      }
      const closingCode = escapeCode ? getClosingCode(escapeCode) : void 0;
      if (escapeCode && closingCode) {
        returnValue += wrapAnsiCode(closingCode);
      }
    } else if (character === "\n") {
      if (escapeCode && getClosingCode(escapeCode)) {
        returnValue += wrapAnsiCode(escapeCode);
      }
      if (escapeUrl) {
        returnValue += wrapAnsiHyperlink(escapeUrl);
      }
    }
  }
  return returnValue;
};
var CRLF_OR_LF = /\r?\n/;
function wrapAnsi(string, columns, options) {
  return String(string).normalize().split(CRLF_OR_LF).map((line) => exec(line, columns, options)).join("\n");
}

// node_modules/@clack/core/dist/index.mjs
var import_sisteransi = __toESM(require_src(), 1);
var import_node_tty = require("node:tty");
function findCursor(s, o2, l2) {
  if (!l2.some((r2) => !r2.disabled))
    return s;
  const t2 = s + o2, n2 = Math.max(l2.length - 1, 0), e = t2 < 0 ? n2 : t2 > n2 ? 0 : t2;
  return l2[e].disabled ? findCursor(e, o2 < 0 ? -1 : 1, l2) : e;
}
var a$2 = ["up", "down", "left", "right", "space", "enter", "cancel"];
var t = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
];
var settings = {
  actions: new Set(a$2),
  aliases: /* @__PURE__ */ new Map([
    // vim support
    ["k", "up"],
    ["j", "down"],
    ["h", "left"],
    ["l", "right"],
    ["", "cancel"],
    // opinionated defaults!
    ["escape", "cancel"]
  ]),
  messages: {
    cancel: "Canceled",
    error: "Something went wrong"
  },
  withGuide: true,
  date: {
    monthNames: [...t],
    messages: {
      required: "Please enter a valid date",
      invalidMonth: "There are only 12 months in a year",
      invalidDay: (n2, e) => `There are only ${n2} days in ${e}`,
      afterMin: (n2) => `Date must be on or after ${n2.toISOString().slice(0, 10)}`,
      beforeMax: (n2) => `Date must be on or before ${n2.toISOString().slice(0, 10)}`
    }
  }
};
function isActionKey(n2, e) {
  if (typeof n2 == "string")
    return settings.aliases.get(n2) === e;
  for (const s of n2)
    if (s !== void 0 && isActionKey(s, e))
      return true;
  return false;
}
function diffLines(i2, s) {
  if (i2 === s) return;
  const e = i2.split(`
`), t2 = s.split(`
`), r2 = Math.max(e.length, t2.length), f = [];
  for (let n2 = 0; n2 < r2; n2++)
    e[n2] !== t2[n2] && f.push(n2);
  return {
    lines: f,
    numLinesBefore: e.length,
    numLinesAfter: t2.length,
    numLines: r2
  };
}
var R2 = globalThis.process.platform.startsWith("win");
var CANCEL_SYMBOL = Symbol("clack:cancel");
function isCancel(e) {
  return e === CANCEL_SYMBOL;
}
function setRawMode(e, r2) {
  const o2 = e;
  o2.isTTY && o2.setRawMode(r2);
}
function block({
  input: e = import_node_process.stdin,
  output: r2 = import_node_process.stdout,
  overwrite: o2 = true,
  hideCursor: t2 = true
} = {}) {
  const s = l.createInterface({
    input: e,
    output: r2,
    prompt: "",
    tabSize: 1
  });
  l.emitKeypressEvents(e, s), e instanceof import_node_tty.ReadStream && e.isTTY && e.setRawMode(true);
  const n2 = (f, { name: a2, sequence: p }) => {
    const c2 = String(f);
    if (isActionKey([c2, a2, p], "cancel")) {
      t2 && r2.write(import_sisteransi.cursor.show), process.exit(0);
      return;
    }
    if (!o2) return;
    const i2 = a2 === "return" ? 0 : -1, m3 = a2 === "return" ? -1 : 0;
    l.moveCursor(r2, i2, m3, () => {
      l.clearLine(r2, 1, () => {
        e.once("keypress", n2);
      });
    });
  };
  return t2 && r2.write(import_sisteransi.cursor.hide), e.once("keypress", n2), () => {
    e.off("keypress", n2), t2 && r2.write(import_sisteransi.cursor.show), e instanceof import_node_tty.ReadStream && e.isTTY && !R2 && e.setRawMode(false), s.terminal = false, s.close();
  };
}
var getColumns = (e) => "columns" in e && typeof e.columns == "number" ? e.columns : 80;
var getRows = (e) => "rows" in e && typeof e.rows == "number" ? e.rows : 20;
function wrapTextWithPrefix(e, r2, o2, t2 = o2, s = o2, n2) {
  const f = getColumns(e ?? import_node_process.stdout);
  return wrapAnsi(r2, f - o2.length, {
    hard: true,
    trim: false
  }).split(`
`).map((c2, i2, m3) => {
    const d = n2 ? n2(c2, i2) : c2;
    return i2 === 0 ? `${t2}${d}` : i2 === m3.length - 1 ? `${s}${d}` : `${o2}${d}`;
  }).join(`
`);
}
function runValidation(e, n2) {
  if ("~standard" in e) {
    const a2 = e["~standard"].validate(n2);
    if (a2 instanceof Promise)
      throw new TypeError(
        "Schema validation must be synchronous. Update `validate()` and remove any asynchronous logic."
      );
    return a2.issues?.at(0)?.message;
  }
  return e(n2);
}
var V = class {
  input;
  output;
  _abortSignal;
  rl;
  opts;
  _render;
  _track = false;
  _prevFrame = "";
  _subscribers = /* @__PURE__ */ new Map();
  _cursor = 0;
  state = "initial";
  error = "";
  value;
  userInput = "";
  constructor(t2, e = true) {
    const { input: i2 = import_node_process.stdin, output: n2 = import_node_process.stdout, render: s, signal: r2, ...o2 } = t2;
    this.opts = o2, this.onKeypress = this.onKeypress.bind(this), this.close = this.close.bind(this), this.render = this.render.bind(this), this._render = s.bind(this), this._track = e, this._abortSignal = r2, this.input = i2, this.output = n2;
  }
  /**
   * Unsubscribe all listeners
   */
  unsubscribe() {
    this._subscribers.clear();
  }
  /**
   * Set a subscriber with opts
   * @param event - The event name
   */
  setSubscriber(t2, e) {
    const i2 = this._subscribers.get(t2) ?? [];
    i2.push(e), this._subscribers.set(t2, i2);
  }
  /**
   * Subscribe to an event
   * @param event - The event name
   * @param cb - The callback
   */
  on(t2, e) {
    this.setSubscriber(t2, { cb: e });
  }
  /**
   * Subscribe to an event once
   * @param event - The event name
   * @param cb - The callback
   */
  once(t2, e) {
    this.setSubscriber(t2, { cb: e, once: true });
  }
  /**
   * Emit an event with data
   * @param event - The event name
   * @param data - The data to pass to the callback
   */
  emit(t2, ...e) {
    const i2 = this._subscribers.get(t2) ?? [], n2 = [];
    for (const s of i2)
      s.cb(...e), s.once && n2.push(() => i2.splice(i2.indexOf(s), 1));
    for (const s of n2)
      s();
  }
  prompt() {
    return new Promise((t2) => {
      if (this._abortSignal) {
        if (this._abortSignal.aborted)
          return this.state = "cancel", this.close(), t2(CANCEL_SYMBOL);
        this._abortSignal.addEventListener(
          "abort",
          () => {
            this.state = "cancel", this.close();
          },
          { once: true }
        );
      }
      this.rl = import_node_readline.default.createInterface({
        input: this.input,
        tabSize: 2,
        prompt: "",
        escapeCodeTimeout: 50,
        terminal: true
      }), this.rl.prompt(), this.opts.initialUserInput !== void 0 && this._setUserInput(this.opts.initialUserInput, true), this.input.on("keypress", this.onKeypress), setRawMode(this.input, true), this.output.on("resize", this.render), this.render(), this.once("submit", () => {
        this.output.write(import_sisteransi.cursor.show), this.output.off("resize", this.render), setRawMode(this.input, false), t2(this.value);
      }), this.once("cancel", () => {
        this.output.write(import_sisteransi.cursor.show), this.output.off("resize", this.render), setRawMode(this.input, false), t2(CANCEL_SYMBOL);
      });
    });
  }
  _isActionKey(t2, e) {
    return t2 === "	";
  }
  _shouldSubmit(t2, e) {
    return true;
  }
  _setValue(t2) {
    this.value = t2, this.emit("value", this.value);
  }
  _setUserInput(t2, e) {
    this.userInput = t2 ?? "", this.emit("userInput", this.userInput), e && this._track && this.rl && (this.rl.write(this.userInput), this._cursor = this.rl.cursor);
  }
  _clearUserInput() {
    this.rl?.write(null, { ctrl: true, name: "u" }), this._setUserInput("");
  }
  onKeypress(t2, e) {
    if (this._track && e.name !== "return" && (e.name && this._isActionKey(t2, e) && this.rl?.write(null, { ctrl: true, name: "h" }), this._cursor = this.rl?.cursor ?? 0, this._setUserInput(this.rl?.line)), this.state === "error" && (this.state = "active"), e?.name && (!this._track && settings.aliases.has(e.name) && this.emit("cursor", settings.aliases.get(e.name)), settings.actions.has(e.name) && this.emit("cursor", e.name)), t2 && (t2.toLowerCase() === "y" || t2.toLowerCase() === "n") && this.emit("confirm", t2.toLowerCase() === "y"), this.emit("key", t2, e), e?.name === "return" && this._shouldSubmit(t2, e)) {
      if (this.opts.validate) {
        const i2 = runValidation(this.opts.validate, this.value);
        i2 && (this.error = i2 instanceof Error ? i2.message : i2, this.state = "error", this.rl?.write(this.userInput));
      }
      this.state !== "error" && (this.state = "submit");
    }
    isActionKey([t2, e?.name, e?.sequence], "cancel") && (this.state = "cancel"), (this.state === "submit" || this.state === "cancel") && this.emit("finalize"), this.render(), (this.state === "submit" || this.state === "cancel") && this.close();
  }
  close() {
    this.input.unpipe(), this.input.removeListener("keypress", this.onKeypress), this.output.write(`
`), setRawMode(this.input, false), this.rl?.close(), this.rl = void 0, this.emit(`${this.state}`, this.value), this.unsubscribe();
  }
  restoreCursor() {
    const t2 = wrapAnsi(this._prevFrame, process.stdout.columns, { hard: true, trim: false }).split(`
`).length - 1;
    this.output.write(import_sisteransi.cursor.move(-999, t2 * -1));
  }
  render() {
    const t2 = wrapAnsi(this._render(this) ?? "", process.stdout.columns, {
      hard: true,
      trim: false
    });
    if (t2 !== this._prevFrame) {
      if (this.state === "initial")
        this.output.write(import_sisteransi.cursor.hide);
      else {
        const e = diffLines(this._prevFrame, t2), i2 = getRows(this.output);
        if (this.restoreCursor(), e) {
          const n2 = Math.max(0, e.numLinesAfter - i2), s = Math.max(0, e.numLinesBefore - i2);
          let r2 = e.lines.find((o2) => o2 >= n2);
          if (r2 === void 0) {
            this._prevFrame = t2;
            return;
          }
          if (e.lines.length === 1) {
            this.output.write(import_sisteransi.cursor.move(0, r2 - s)), this.output.write(import_sisteransi.erase.lines(1));
            const o2 = t2.split(`
`);
            this.output.write(o2[r2]), this._prevFrame = t2, this.output.write(import_sisteransi.cursor.move(0, o2.length - r2 - 1));
            return;
          } else if (e.lines.length > 1) {
            if (n2 < s)
              r2 = n2;
            else {
              const h2 = r2 - s;
              h2 > 0 && this.output.write(import_sisteransi.cursor.move(0, h2));
            }
            this.output.write(import_sisteransi.erase.down());
            const f = t2.split(`
`).slice(r2);
            this.output.write(f.join(`
`)), this._prevFrame = t2;
            return;
          }
        }
        this.output.write(import_sisteransi.erase.down());
      }
      this.output.write(t2), this.state === "initial" && (this.state = "active"), this._prevFrame = t2;
    }
  }
};
function p$1(l2, e) {
  if (l2 === void 0 || e.length === 0)
    return 0;
  const i2 = e.findIndex((s) => s.value === l2);
  return i2 !== -1 ? i2 : 0;
}
function g(l2, e) {
  return (e.label ?? String(e.value)).toLowerCase().includes(l2.toLowerCase());
}
function m2(l2, e) {
  if (e)
    return l2 ? e : e[0];
}
var T$1 = class T extends V {
  filteredOptions;
  multiple;
  isNavigating = false;
  selectedValues = [];
  focusedValue;
  #e = 0;
  #s = "";
  #t;
  #i;
  #n;
  get cursor() {
    return this.#e;
  }
  get userInputWithCursor() {
    if (!this.userInput)
      return (0, import_node_util.styleText)(["inverse", "hidden"], "_");
    if (this._cursor >= this.userInput.length)
      return `${this.userInput}\u2588`;
    const e = this.userInput.slice(0, this._cursor), [t2, ...i2] = this.userInput.slice(this._cursor);
    return `${e}${(0, import_node_util.styleText)("inverse", t2)}${i2.join("")}`;
  }
  get options() {
    return typeof this.#i == "function" ? this.#i() : this.#i;
  }
  constructor(e) {
    super(e), this.#i = e.options, this.#n = e.placeholder;
    const t2 = this.options;
    this.filteredOptions = [...t2], this.multiple = e.multiple === true, this.#t = typeof e.options == "function" ? e.filter : e.filter ?? g;
    let i2;
    if (e.initialValue && Array.isArray(e.initialValue) ? this.multiple ? i2 = e.initialValue : i2 = e.initialValue.slice(0, 1) : !this.multiple && this.options.length > 0 && (i2 = [this.options[0].value]), i2)
      for (const s of i2) {
        const n2 = t2.findIndex((o2) => o2.value === s);
        n2 !== -1 && (this.toggleSelected(s), this.#e = n2);
      }
    this.focusedValue = this.options[this.#e]?.value, this.on("key", (s, n2) => this.#l(s, n2)), this.on("userInput", (s) => this.#u(s));
  }
  _isActionKey(e, t2) {
    return e === "	" || this.multiple && this.isNavigating && t2.name === "space" && e !== void 0 && e !== "";
  }
  #l(e, t2) {
    const i2 = t2.name === "up", s = t2.name === "down", n2 = t2.name === "return", o2 = this.userInput === "" || this.userInput === "	", u3 = this.#n, h2 = this.options, f = u3 !== void 0 && u3 !== "" && h2.some(
      (r2) => !r2.disabled && (this.#t ? this.#t(u3, r2) : true)
    );
    if (t2.name === "tab" && o2 && f) {
      this.userInput === "	" && this._clearUserInput(), this._setUserInput(u3, true), this.isNavigating = false;
      return;
    }
    i2 || s ? (this.#e = findCursor(this.#e, i2 ? -1 : 1, this.filteredOptions), this.focusedValue = this.filteredOptions[this.#e]?.value, this.multiple || (this.selectedValues = [this.focusedValue]), this.isNavigating = true) : n2 ? this.value = m2(this.multiple, this.selectedValues) : this.multiple ? this.focusedValue !== void 0 && (t2.name === "tab" || this.isNavigating && t2.name === "space") ? this.toggleSelected(this.focusedValue) : this.isNavigating = false : (this.focusedValue && (this.selectedValues = [this.focusedValue]), this.isNavigating = false);
  }
  deselectAll() {
    this.selectedValues = [];
  }
  toggleSelected(e) {
    this.filteredOptions.length !== 0 && (this.multiple ? this.selectedValues.includes(e) ? this.selectedValues = this.selectedValues.filter((t2) => t2 !== e) : this.selectedValues = [...this.selectedValues, e] : this.selectedValues = [e]);
  }
  #u(e) {
    if (e !== this.#s) {
      this.#s = e;
      const t2 = this.options;
      e && this.#t ? this.filteredOptions = t2.filter((n2) => this.#t?.(e, n2)) : this.filteredOptions = [...t2];
      const i2 = p$1(this.focusedValue, this.filteredOptions);
      this.#e = findCursor(i2, 0, this.filteredOptions);
      const s = this.filteredOptions[this.#e];
      s && !s.disabled ? this.focusedValue = s.value : this.focusedValue = void 0, this.multiple || (this.focusedValue !== void 0 ? this.toggleSelected(this.focusedValue) : this.deselectAll());
    }
  }
};
var r = class extends V {
  get cursor() {
    return this.value ? 0 : 1;
  }
  get _value() {
    return this.cursor === 0;
  }
  constructor(t2) {
    super(t2, false), this.value = !!t2.initialValue, this.on("userInput", () => {
      this.value = this._value;
    }), this.on("confirm", (i2) => {
      this.output.write(import_sisteransi.cursor.move(0, -1)), this.value = i2, this.state = "submit", this.close();
    }), this.on("cursor", () => {
      this.value = !this.value;
    });
  }
};
var a = class extends V {
  options;
  cursor = 0;
  get _selectedValue() {
    return this.options[this.cursor];
  }
  changeValue() {
    this.value = this._selectedValue.value;
  }
  constructor(t2) {
    super(t2, false), this.options = t2.options;
    const i2 = this.options.findIndex(({ value: s }) => s === t2.initialValue), e = i2 === -1 ? 0 : i2;
    this.cursor = this.options[e].disabled ? findCursor(e, 1, this.options) : e, this.changeValue(), this.on("cursor", (s) => {
      switch (s) {
        case "left":
        case "up":
          this.cursor = findCursor(this.cursor, -1, this.options);
          break;
        case "down":
        case "right":
          this.cursor = findCursor(this.cursor, 1, this.options);
          break;
      }
      this.changeValue();
    });
  }
};

// node_modules/@clack/prompts/dist/index.mjs
var import_node_util2 = require("node:util");
var import_node_process2 = __toESM(require("node:process"), 1);
var import_sisteransi2 = __toESM(require_src(), 1);
function isUnicodeSupported() {
  if (import_node_process2.default.platform !== "win32") {
    return import_node_process2.default.env.TERM !== "linux";
  }
  return Boolean(import_node_process2.default.env.CI) || Boolean(import_node_process2.default.env.WT_SESSION) || Boolean(import_node_process2.default.env.TERMINUS_SUBLIME) || import_node_process2.default.env.ConEmuTask === "{cmd::Cmder}" || import_node_process2.default.env.TERM_PROGRAM === "Terminus-Sublime" || import_node_process2.default.env.TERM_PROGRAM === "vscode" || import_node_process2.default.env.TERM === "xterm-256color" || import_node_process2.default.env.TERM === "alacritty" || import_node_process2.default.env.TERMINAL_EMULATOR === "JetBrains-JediTerm";
}
var unicode = isUnicodeSupported();
var isCI = () => process.env.CI === "true";
var unicodeOr = (e, o2) => unicode ? e : o2;
var S_STEP_ACTIVE = unicodeOr("\u25C6", "*");
var S_STEP_CANCEL = unicodeOr("\u25A0", "x");
var S_STEP_ERROR = unicodeOr("\u25B2", "x");
var S_STEP_SUBMIT = unicodeOr("\u25C7", "o");
var S_BAR_START = unicodeOr("\u250C", "T");
var S_BAR = unicodeOr("\u2502", "|");
var S_BAR_END = unicodeOr("\u2514", "\u2014");
var S_BAR_START_RIGHT = unicodeOr("\u2510", "T");
var S_BAR_END_RIGHT = unicodeOr("\u2518", "\u2014");
var S_RADIO_ACTIVE = unicodeOr("\u25CF", ">");
var S_RADIO_INACTIVE = unicodeOr("\u25CB", " ");
var S_CHECKBOX_ACTIVE = unicodeOr("\u25FB", "[\u2022]");
var S_CHECKBOX_SELECTED = unicodeOr("\u25FC", "[+]");
var S_CHECKBOX_INACTIVE = unicodeOr("\u25FB", "[ ]");
var S_PASSWORD_MASK = unicodeOr("\u25AA", "\u2022");
var S_BAR_H = unicodeOr("\u2500", "-");
var S_CORNER_TOP_RIGHT = unicodeOr("\u256E", "+");
var S_CONNECT_LEFT = unicodeOr("\u251C", "+");
var S_CORNER_BOTTOM_RIGHT = unicodeOr("\u256F", "+");
var S_CORNER_BOTTOM_LEFT = unicodeOr("\u2570", "+");
var S_CORNER_TOP_LEFT = unicodeOr("\u256D", "+");
var S_INFO = unicodeOr("\u25CF", "\u2022");
var S_SUCCESS = unicodeOr("\u25C6", "*");
var S_WARN = unicodeOr("\u25B2", "!");
var S_ERROR = unicodeOr("\u25A0", "x");
var symbol = (e) => {
  switch (e) {
    case "initial":
    case "active":
      return (0, import_node_util2.styleText)("cyan", S_STEP_ACTIVE);
    case "cancel":
      return (0, import_node_util2.styleText)("red", S_STEP_CANCEL);
    case "error":
      return (0, import_node_util2.styleText)("yellow", S_STEP_ERROR);
    case "submit":
      return (0, import_node_util2.styleText)("green", S_STEP_SUBMIT);
  }
};
var symbolBar = (e) => {
  switch (e) {
    case "initial":
    case "active":
      return (0, import_node_util2.styleText)("cyan", S_BAR);
    case "cancel":
      return (0, import_node_util2.styleText)("red", S_BAR);
    case "error":
      return (0, import_node_util2.styleText)("yellow", S_BAR);
    case "submit":
      return (0, import_node_util2.styleText)("green", S_BAR);
  }
};
var E$1 = (l2, o2, g2, c2, h2, O = false) => {
  let r2 = o2, w = 0;
  if (O)
    for (let i2 = c2 - 1; i2 >= g2 && (r2 -= l2[i2].length, w++, !(r2 <= h2)); i2--)
      ;
  else
    for (let i2 = g2; i2 < c2 && (r2 -= l2[i2].length, w++, !(r2 <= h2)); i2++)
      ;
  return { lineCount: r2, removals: w };
};
var limitOptions = ({
  cursor: l2,
  options: o2,
  style: g2,
  output: c2 = process.stdout,
  maxItems: h2 = Number.POSITIVE_INFINITY,
  columnPadding: O = 0,
  rowPadding: r2 = 4
}) => {
  const i2 = getColumns(c2) - O, I = getRows(c2), C2 = (0, import_node_util2.styleText)("dim", "..."), x = Math.max(I - r2, 0), m3 = Math.max(Math.min(h2, x), 5);
  let p = 0;
  l2 >= m3 - 3 && (p = Math.max(
    Math.min(l2 - m3 + 3, o2.length - m3),
    0
  ));
  let f = m3 < o2.length && p > 0, u3 = m3 < o2.length && p + m3 < o2.length;
  const W2 = Math.min(
    p + m3,
    o2.length
  ), e = [];
  let d = 0;
  f && d++, u3 && d++;
  const v = p + (f ? 1 : 0), P2 = W2 - (u3 ? 1 : 0);
  for (let t2 = v; t2 < P2; t2++) {
    const n2 = wrapAnsi(g2(o2[t2], t2 === l2), i2, {
      hard: true,
      trim: false
    }).split(`
`);
    e.push(n2), d += n2.length;
  }
  if (d > x) {
    let t2 = 0, n2 = 0, s = d;
    const M = l2 - v;
    let a2 = x;
    const T2 = () => E$1(e, s, 0, M, a2), L = () => E$1(
      e,
      s,
      M + 1,
      e.length,
      a2,
      true
    );
    f ? ({ lineCount: s, removals: t2 } = T2(), s > a2 && (u3 || (a2 -= 1), { lineCount: s, removals: n2 } = L())) : (u3 || (a2 -= 1), { lineCount: s, removals: n2 } = L(), s > a2 && (a2 -= 1, { lineCount: s, removals: t2 } = T2())), t2 > 0 && (f = true, e.splice(0, t2)), n2 > 0 && (u3 = true, e.splice(e.length - n2, n2));
  }
  const b = [];
  f && b.push(C2);
  for (const t2 of e)
    for (const n2 of t2)
      b.push(n2);
  return u3 && b.push(C2), b;
};
function P(t2) {
  return t2.label ?? String(t2.value ?? "");
}
function E(t2, c2) {
  if (!t2)
    return true;
  const n2 = (c2.label ?? String(c2.value ?? "")).toLowerCase(), i2 = (c2.hint ?? "").toLowerCase(), l2 = String(c2.value).toLowerCase(), o2 = t2.toLowerCase();
  return n2.includes(o2) || i2.includes(o2) || l2.includes(o2);
}
function N(t2, c2) {
  const n2 = [];
  for (const i2 of c2)
    t2.includes(i2.value) && n2.push(i2);
  return n2;
}
var autocomplete = (t2) => new T$1({
  options: t2.options,
  initialValue: t2.initialValue ? [t2.initialValue] : void 0,
  initialUserInput: t2.initialUserInput,
  placeholder: t2.placeholder,
  filter: t2.filter ?? ((n2, i2) => E(n2, i2)),
  signal: t2.signal,
  input: t2.input,
  output: t2.output,
  validate: t2.validate,
  render() {
    const n2 = t2.withGuide ?? settings.withGuide, i2 = n2 ? [`${(0, import_node_util2.styleText)("gray", S_BAR)}`, `${symbol(this.state)}  ${t2.message}`] : [`${symbol(this.state)}  ${t2.message}`], l2 = this.userInput, o2 = this.options, m3 = t2.placeholder, p = l2 === "" && m3 !== void 0, $ = (r2, s) => {
      const a2 = P(r2), u3 = r2.hint && r2.value === this.focusedValue ? (0, import_node_util2.styleText)("dim", ` (${r2.hint})`) : "";
      switch (s) {
        case "active":
          return `${(0, import_node_util2.styleText)("green", S_RADIO_ACTIVE)} ${a2}${u3}`;
        case "inactive":
          return `${(0, import_node_util2.styleText)("dim", S_RADIO_INACTIVE)} ${(0, import_node_util2.styleText)("dim", a2)}`;
        case "disabled":
          return `${(0, import_node_util2.styleText)("gray", S_RADIO_INACTIVE)} ${(0, import_node_util2.styleText)(["strikethrough", "gray"], a2)}`;
      }
    };
    switch (this.state) {
      case "submit": {
        const r2 = N(this.selectedValues, o2), s = r2.length > 0 ? `  ${(0, import_node_util2.styleText)("dim", r2.map(P).join(", "))}` : "", a2 = n2 ? (0, import_node_util2.styleText)("gray", S_BAR) : "";
        return `${i2.join(`
`)}
${a2}${s}`;
      }
      case "cancel": {
        const r2 = l2 ? `  ${(0, import_node_util2.styleText)(["strikethrough", "dim"], l2)}` : "", s = n2 ? (0, import_node_util2.styleText)("gray", S_BAR) : "";
        return `${i2.join(`
`)}
${s}${r2}`;
      }
      default: {
        const r2 = this.state === "error" ? "yellow" : "cyan", s = n2 ? `${(0, import_node_util2.styleText)(r2, S_BAR)}  ` : "", a2 = n2 ? (0, import_node_util2.styleText)(r2, S_BAR_END) : "";
        let u3 = "";
        if (this.isNavigating || p) {
          const d = p ? m3 : l2;
          u3 = d !== "" ? ` ${(0, import_node_util2.styleText)("dim", d)}` : "";
        } else
          u3 = ` ${this.userInputWithCursor}`;
        const V2 = this.filteredOptions.length !== o2.length ? (0, import_node_util2.styleText)(
          "dim",
          ` (${this.filteredOptions.length} match${this.filteredOptions.length === 1 ? "" : "es"})`
        ) : "", y = this.filteredOptions.length === 0 && l2 ? [`${s}${(0, import_node_util2.styleText)("yellow", "No matches found")}`] : [], b = this.state === "error" ? [`${s}${(0, import_node_util2.styleText)("yellow", this.error)}`] : [];
        n2 && i2.push(`${s.trimEnd()}`), i2.push(
          `${s}${(0, import_node_util2.styleText)("dim", "Search:")}${u3}${V2}`,
          ...y,
          ...b
        );
        const v = [
          `${(0, import_node_util2.styleText)("dim", "\u2191/\u2193")} to select`,
          `${(0, import_node_util2.styleText)("dim", "Enter:")} confirm`,
          `${(0, import_node_util2.styleText)("dim", "Type:")} to search`
        ], g2 = [`${s}${v.join(" \u2022 ")}`, a2], O = this.filteredOptions.length === 0 ? [] : limitOptions({
          cursor: this.cursor,
          options: this.filteredOptions,
          columnPadding: n2 ? 3 : 0,
          // for `|  ` when guide is shown
          rowPadding: i2.length + g2.length,
          style: (d, f) => $(
            d,
            d.disabled ? "disabled" : f ? "active" : "inactive"
          ),
          maxItems: t2.maxItems,
          output: t2.output
        });
        return [
          ...i2,
          ...O.map((d) => `${s}${d}`),
          ...g2
        ].join(`
`);
      }
    }
  }
}).prompt();
var confirm = (i2) => {
  const a2 = i2.active ?? "Yes", s = i2.inactive ?? "No";
  return new r({
    active: a2,
    inactive: s,
    signal: i2.signal,
    input: i2.input,
    output: i2.output,
    initialValue: i2.initialValue ?? true,
    render() {
      const e = i2.withGuide ?? settings.withGuide, u3 = `${symbol(this.state)}  `, l2 = e ? `${(0, import_node_util2.styleText)("gray", S_BAR)}  ` : "", f = wrapTextWithPrefix(
        i2.output,
        i2.message,
        l2,
        u3
      ), o2 = `${e ? `${(0, import_node_util2.styleText)("gray", S_BAR)}
` : ""}${f}
`, c2 = this.value ? a2 : s;
      switch (this.state) {
        case "submit": {
          const r2 = e ? `${(0, import_node_util2.styleText)("gray", S_BAR)}  ` : "";
          return `${o2}${r2}${(0, import_node_util2.styleText)("dim", c2)}`;
        }
        case "cancel": {
          const r2 = e ? `${(0, import_node_util2.styleText)("gray", S_BAR)}  ` : "";
          return `${o2}${r2}${(0, import_node_util2.styleText)(["strikethrough", "dim"], c2)}${e ? `
${(0, import_node_util2.styleText)("gray", S_BAR)}` : ""}`;
        }
        default: {
          const r2 = e ? `${(0, import_node_util2.styleText)("cyan", S_BAR)}  ` : "", g2 = e ? (0, import_node_util2.styleText)("cyan", S_BAR_END) : "";
          return `${o2}${r2}${this.value ? `${(0, import_node_util2.styleText)("green", S_RADIO_ACTIVE)} ${a2}` : `${(0, import_node_util2.styleText)("dim", S_RADIO_INACTIVE)} ${(0, import_node_util2.styleText)("dim", a2)}`}${i2.vertical ? e ? `
${(0, import_node_util2.styleText)("cyan", S_BAR)}  ` : `
` : ` ${(0, import_node_util2.styleText)("dim", "/")} `}${this.value ? `${(0, import_node_util2.styleText)("dim", S_RADIO_INACTIVE)} ${(0, import_node_util2.styleText)("dim", s)}` : `${(0, import_node_util2.styleText)("green", S_RADIO_ACTIVE)} ${s}`}
${g2}
`;
        }
      }
    }
  }).prompt();
};
var cancel = (o2 = "", t2) => {
  const i2 = t2?.output ?? process.stdout, e = t2?.withGuide ?? settings.withGuide ? `${(0, import_node_util2.styleText)("gray", S_BAR_END)}  ` : "";
  i2.write(`${e}${(0, import_node_util2.styleText)("red", o2)}

`);
};
var intro = (o2 = "", t2) => {
  const i2 = t2?.output ?? process.stdout, e = t2?.withGuide ?? settings.withGuide ? `${(0, import_node_util2.styleText)("gray", S_BAR_START)}  ` : "";
  i2.write(`${e}${o2}
`);
};
var outro = (o2 = "", t2) => {
  const i2 = t2?.output ?? process.stdout, e = t2?.withGuide ?? settings.withGuide ? `${(0, import_node_util2.styleText)("gray", S_BAR)}
${(0, import_node_util2.styleText)("gray", S_BAR_END)}  ` : "";
  i2.write(`${e}${o2}

`);
};
var W$1 = (o2) => (0, import_node_util2.styleText)("dim", o2);
var C = (o2, e, s) => {
  const a2 = {
    hard: true,
    trim: false
  }, i2 = wrapAnsi(o2, e, a2).split(`
`), c2 = i2.reduce((n2, r2) => Math.max(dist_default2(r2), n2), 0), u3 = i2.map(s).reduce((n2, r2) => Math.max(dist_default2(r2), n2), 0), g2 = e - (u3 - c2);
  return wrapAnsi(o2, g2, a2);
};
var note = (o2 = "", e = "", s) => {
  const a2 = s?.output ?? import_node_process2.default.stdout, i2 = s?.withGuide ?? settings.withGuide, c2 = s?.format ?? W$1, g2 = ["", ...C(o2, getColumns(a2) - 6, c2).split(`
`).map(c2), ""], n2 = dist_default2(e), r2 = Math.max(
    g2.reduce((m3, F) => {
      const O = dist_default2(F);
      return O > m3 ? O : m3;
    }, 0),
    n2
  ) + 2, h2 = g2.map(
    (m3) => `${(0, import_node_util2.styleText)("gray", S_BAR)}  ${m3}${" ".repeat(r2 - dist_default2(m3))}${(0, import_node_util2.styleText)("gray", S_BAR)}`
  ).join(`
`), T2 = i2 ? `${(0, import_node_util2.styleText)("gray", S_BAR)}
` : "", l$1 = i2 ? S_CONNECT_LEFT : S_CORNER_BOTTOM_LEFT;
  a2.write(
    `${T2}${(0, import_node_util2.styleText)("green", S_STEP_SUBMIT)}  ${(0, import_node_util2.styleText)("reset", e)} ${(0, import_node_util2.styleText)(
      "gray",
      S_BAR_H.repeat(Math.max(r2 - n2 - 1, 1)) + S_CORNER_TOP_RIGHT
    )}
${h2}
${(0, import_node_util2.styleText)("gray", l$1 + S_BAR_H.repeat(r2 + 2) + S_CORNER_BOTTOM_RIGHT)}
`
  );
};
var W = (l2) => (0, import_node_util2.styleText)("magenta", l2);
var spinner = ({
  indicator: l2 = "dots",
  onCancel: h2,
  output: n2 = process.stdout,
  cancelMessage: G,
  errorMessage: O,
  frames: E2 = unicode ? ["\u25D2", "\u25D0", "\u25D3", "\u25D1"] : ["\u2022", "o", "O", "0"],
  delay: F = unicode ? 80 : 120,
  signal: m3,
  ...I
} = {}) => {
  const u3 = isCI();
  let M, T2, d = false, S = false, s = "", p, w = performance.now();
  const x = getColumns(n2), k = I?.styleFrame ?? W, g2 = (e) => {
    const r2 = e > 1 ? O ?? settings.messages.error : G ?? settings.messages.cancel;
    S = e === 1, d && (a2(r2, e), S && typeof h2 == "function" && h2());
  }, f = () => g2(2), i2 = () => g2(1), A = () => {
    process.on("uncaughtExceptionMonitor", f), process.on("unhandledRejection", f), process.on("SIGINT", i2), process.on("SIGTERM", i2), process.on("exit", g2), m3 && m3.addEventListener("abort", i2);
  }, H = () => {
    process.removeListener("uncaughtExceptionMonitor", f), process.removeListener("unhandledRejection", f), process.removeListener("SIGINT", i2), process.removeListener("SIGTERM", i2), process.removeListener("exit", g2), m3 && m3.removeEventListener("abort", i2);
  }, y = () => {
    if (p === void 0) return;
    u3 && n2.write(`
`);
    const r2 = wrapAnsi(p, x, {
      hard: true,
      trim: false
    }).split(`
`);
    r2.length > 1 && n2.write(import_sisteransi2.cursor.up(r2.length - 1)), n2.write(import_sisteransi2.cursor.to(0)), n2.write(import_sisteransi2.erase.down());
  }, C2 = (e) => e.replace(/\.+$/, ""), _ = (e) => {
    const r2 = (performance.now() - e) / 1e3, t2 = Math.floor(r2 / 60), o2 = Math.floor(r2 % 60);
    return t2 > 0 ? `[${t2}m ${o2}s]` : `[${o2}s]`;
  }, N2 = I.withGuide ?? settings.withGuide, P2 = (e = "") => {
    d = true, M = block({ output: n2 }), s = C2(e), w = performance.now(), N2 && n2.write(`${(0, import_node_util2.styleText)("gray", S_BAR)}
`);
    let r2 = 0, t2 = 0;
    A(), T2 = setInterval(() => {
      if (u3 && s === p)
        return;
      y(), p = s;
      const o2 = k(E2[r2]);
      let v;
      if (u3)
        v = `${o2}  ${s}...`;
      else if (l2 === "timer")
        v = `${o2}  ${s} ${_(w)}`;
      else {
        const B2 = ".".repeat(Math.floor(t2)).slice(0, 3);
        v = `${o2}  ${s}${B2}`;
      }
      const j = wrapAnsi(v, x, {
        hard: true,
        trim: false
      });
      n2.write(j), r2 = r2 + 1 < E2.length ? r2 + 1 : 0, t2 = t2 < 4 ? t2 + 0.125 : 0;
    }, F);
  }, a2 = (e = "", r2 = 0, t2 = false) => {
    if (!d) return;
    d = false, clearInterval(T2), y();
    const o2 = r2 === 0 ? (0, import_node_util2.styleText)("green", S_STEP_SUBMIT) : r2 === 1 ? (0, import_node_util2.styleText)("red", S_STEP_CANCEL) : (0, import_node_util2.styleText)("red", S_STEP_ERROR);
    s = e ?? s, t2 || (l2 === "timer" ? n2.write(`${o2}  ${s} ${_(w)}
`) : n2.write(`${o2}  ${s}
`)), H(), M();
  };
  return {
    start: P2,
    stop: (e = "") => a2(e, 0),
    message: (e = "") => {
      s = C2(e ?? s);
    },
    cancel: (e = "") => a2(e, 1),
    error: (e = "") => a2(e, 2),
    clear: () => a2("", 0, true),
    get isCancelled() {
      return S;
    }
  };
};
var u2 = {
  light: unicodeOr("\u2500", "-"),
  heavy: unicodeOr("\u2501", "="),
  block: unicodeOr("\u2588", "#")
};
var c = (e, a2) => e.includes(`
`) ? e.split(`
`).map((t2) => a2(t2)).join(`
`) : a2(e);
var select = (e) => {
  const a2 = (t2, d) => {
    const s = t2.label ?? String(t2.value);
    switch (d) {
      case "disabled":
        return `${(0, import_node_util2.styleText)("gray", S_RADIO_INACTIVE)} ${c(s, (n2) => (0, import_node_util2.styleText)("gray", n2))}${t2.hint ? ` ${(0, import_node_util2.styleText)("dim", `(${t2.hint ?? "disabled"})`)}` : ""}`;
      case "selected":
        return `${c(s, (n2) => (0, import_node_util2.styleText)("dim", n2))}`;
      case "active":
        return `${(0, import_node_util2.styleText)("green", S_RADIO_ACTIVE)} ${s}${t2.hint ? ` ${(0, import_node_util2.styleText)("dim", `(${t2.hint})`)}` : ""}`;
      case "cancelled":
        return `${c(s, (n2) => (0, import_node_util2.styleText)(["strikethrough", "dim"], n2))}`;
      default:
        return `${(0, import_node_util2.styleText)("dim", S_RADIO_INACTIVE)} ${c(s, (n2) => (0, import_node_util2.styleText)("dim", n2))}`;
    }
  };
  return new a({
    options: e.options,
    signal: e.signal,
    input: e.input,
    output: e.output,
    initialValue: e.initialValue,
    render() {
      const t2 = e.withGuide ?? settings.withGuide, d = `${symbol(this.state)}  `, s = `${symbolBar(this.state)}  `, n2 = wrapTextWithPrefix(
        e.output,
        e.message,
        s,
        d
      ), u3 = `${t2 ? `${(0, import_node_util2.styleText)("gray", S_BAR)}
` : ""}${n2}
`;
      switch (this.state) {
        case "submit": {
          const r2 = t2 ? `${(0, import_node_util2.styleText)("gray", S_BAR)}  ` : "", l2 = wrapTextWithPrefix(
            e.output,
            a2(this.options[this.cursor], "selected"),
            r2
          );
          return `${u3}${l2}`;
        }
        case "cancel": {
          const r2 = t2 ? `${(0, import_node_util2.styleText)("gray", S_BAR)}  ` : "", l2 = wrapTextWithPrefix(
            e.output,
            a2(this.options[this.cursor], "cancelled"),
            r2
          );
          return `${u3}${l2}${t2 ? `
${(0, import_node_util2.styleText)("gray", S_BAR)}` : ""}`;
        }
        default: {
          const r2 = t2 ? `${(0, import_node_util2.styleText)("cyan", S_BAR)}  ` : "", l2 = t2 ? (0, import_node_util2.styleText)("cyan", S_BAR_END) : "", g2 = u3.split(`
`).length, h2 = t2 ? 2 : 1;
          return `${u3}${r2}${limitOptions({
            output: e.output,
            cursor: this.cursor,
            options: this.options,
            maxItems: e.maxItems,
            columnPadding: r2.length,
            rowPadding: g2 + h2,
            style: (p, b) => a2(p, p.disabled ? "disabled" : b ? "active" : "inactive")
          }).join(`
${r2}`)}
${l2}
`;
        }
      }
    }
  }).prompt();
};
var i = `${(0, import_node_util2.styleText)("gray", S_BAR)}  `;

// src/prompter.ts
var WizardCancelledError = class extends Error {
  name = "WizardCancelledError";
};
function guardCancel(value, cancelledLabel = "Abgebrochen.") {
  if (isCancel(value)) {
    cancel(styleTitle(cancelledLabel));
    throw new WizardCancelledError();
  }
  return value;
}
function toClackOptions(options) {
  return options.map((opt) => {
    const base = { value: opt.value, label: opt.label };
    if (opt.hint) {
      return { ...base, hint: opt.hint };
    }
    return base;
  });
}
function createCrkcachyPrompter() {
  return {
    intro: async (title) => {
      intro(styleTitle(title));
    },
    outro: async (message) => {
      outro(styleSuccess(message));
    },
    note: async (message, title) => {
      note(message, title ? styleTitle(title) : void 0);
    },
    select: async ({ message, options, initialValue }) => {
      return guardCancel(
        await select({
          message: styleMessage(message),
          options: toClackOptions(options),
          initialValue
        })
      );
    },
    autocomplete: async ({ message, options, initialValue, placeholder }) => {
      return guardCancel(
        await autocomplete({
          message: styleMessage(message),
          options: toClackOptions(options),
          initialValue,
          placeholder: placeholder ? styleHint(placeholder) : void 0
        })
      );
    },
    confirm: async (message, initialValue = false) => {
      return guardCancel(
        await confirm({
          message: styleMessage(message),
          initialValue
        })
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
    pressContinue: async (message, label = "Weiter") => {
      guardCancel(
        await select({
          message: message ? styleMessage(message) : styleHint("Fortfahren"),
          options: [{ value: "ok", label: styleLabel(label) }],
          initialValue: "ok"
        })
      );
    }
  };
}
function restoreTerminalGap() {
  process.stdout.write("\n");
}

// src/wizard.ts
function parseArgs(argv) {
  let root2 = process.env.CRKCACHY_ROOT ?? "";
  let lang = process.env.CRKCACHY_LANG;
  for (let i2 = 2; i2 < argv.length; i2++) {
    const arg = argv[i2];
    if (arg === "--root" && argv[i2 + 1]) {
      root2 = argv[++i2];
    } else if (arg === "--lang" && argv[i2 + 1]) {
      lang = argv[++i2];
    } else if (arg.startsWith("--lang=")) {
      lang = arg.slice("--lang=".length);
    }
  }
  if (!root2) {
    root2 = (0, import_node_path2.join)(__dirname, "..", "..");
  }
  if (lang) {
    process.env.CRKCACHY_LANG = lang;
  }
  return { root: root2, lang };
}
function hasInteractiveTty() {
  if (process.stdin.isTTY && process.stdout.isTTY) return true;
  try {
    return (0, import_node_fs2.existsSync)("/dev/tty");
  } catch {
    return false;
  }
}
function recommendedHint(ctx) {
  switch (ctx.assess.recommended) {
    case 3:
      return m("", ctx, "wizard.hint_ready");
    case 2:
      return m("", ctx, "wizard.hint_fix");
    default:
      return m("", ctx, "wizard.hint_full");
  }
}
function buildMenuOptions(ctx) {
  const badge = m("", ctx, "ui.badge_recommended");
  const rec = String(ctx.assess.recommended);
  const options = [];
  const addOpt = (n2) => {
    const label = m("", ctx, `wizard.opt${n2}`);
    const isRec = String(n2) === rec;
    const styledLabel = isRec ? `${iconStep()} ${styleSuccess(badge)}  ${styleLabel(label)}` : n2 === 5 ? `${styleWarning("\u25CB")} ${styleLabel(label)}` : styleLabel(label);
    options.push({
      value: String(n2),
      label: styledLabel
    });
  };
  addOpt(ctx.assess.recommended);
  for (const n2 of [1, 2, 3]) {
    if (String(n2) !== rec) addOpt(n2);
  }
  if (ctx.assess.recommended !== 4) {
    addOpt(4);
  }
  addOpt(5);
  return options;
}
function buildStyledStatusNote(ctx) {
  if (ctx.assess.systemReady) {
    return `${iconOk()} ${styleSuccess(ctx.assess.hint)}`;
  }
  const lines = [
    `${iconWarn()} ${styleWarning(mf("", ctx, "wizard.status_fix", ctx.assess.score))}`,
    ""
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
async function ensureGlowRuntime(root2, ctx, p) {
  if (ctx.runtime.glowOk) return;
  await p.note(
    m("", ctx, "runtime.bootstrap_body"),
    m("", ctx, "runtime.bootstrap_title")
  );
  while (true) {
    const pick = await p.select({
      message: m("", ctx, "glow.pick_title"),
      options: [
        { value: "auto", label: m("", ctx, "glow.opt_auto") },
        { value: "manual", label: m("", ctx, "glow.opt_manual") }
      ],
      initialValue: "auto"
    });
    restoreTerminalGap();
    if (pick === "auto") {
      await p.spin(m("", ctx, "glow.password_hint"), async () => {
        if (!installGlow(root2, "auto")) {
          throw new Error(m("", ctx, "glow.install_failed"));
        }
      });
    } else {
      installGlow(root2, "manual");
      await p.note(
        `${m("", ctx, "glow.manual_steps_intro")}

${m("", ctx, "pkg.explain.footer")}`,
        m("", ctx, "glow.missing_title")
      );
    }
    const refreshed = await loadContext(root2);
    if (refreshed.runtime.glowOk) {
      await p.note(m("", ctx, "glow.installed"));
      return;
    }
    await p.note(m("", ctx, "glow.still_missing"));
  }
}
async function runLegalGate(root2, ctx, p) {
  const steps = [
    { title: m("", ctx, "legal.step1_title"), body: m("", ctx, "legal.step1_body") },
    { title: m("", ctx, "legal.step2_title"), body: m("", ctx, "legal.step2_body") },
    { title: m("", ctx, "legal.step3_title"), body: m("", ctx, "legal.step3_body") },
    { title: m("", ctx, "legal.step4_title"), body: m("", ctx, "legal.step4_body") }
  ];
  for (const step of steps) {
    await p.note(step.body, step.title);
  }
  await p.note(m("", ctx, "install.legal_summary"));
  const ok = await p.confirm(m("", ctx, "ui.legal_confirm"), false);
  if (!ok) {
    throw new Error(m("", ctx, "runtime.legal_abort"));
  }
  legalAccept(root2);
}
async function runPreflightGates(root2, ctx, p) {
  const state = loadPreflightState(root2);
  if (state.recommendedFail > 0 && state.requiredFail === 0) {
    const fix = await p.confirm(m("", ctx, "runtime.fix_recommended"), false);
    if (fix) {
      restoreTerminalGap();
      await bridgeRunInteractive(root2, "preflight-fix-recommended");
    }
  }
  const after = loadPreflightState(root2);
  if (after.requiredFail > 0) {
    throw new Error(m("", ctx, "runtime.cannot_continue"));
  }
  if (!state.skipLegal) {
    await runLegalGate(root2, ctx, p);
  }
}
async function pickTool(root2, ctx, p, uninstall = false) {
  const tools = loadToolsList(root2);
  if (tools.length === 0) {
    await p.note(m("", ctx, "tools.none"));
    return null;
  }
  const options = tools.map((t2) => ({
    value: t2.slug,
    label: t2.label
  }));
  if (!uninstall) {
    options.push({ value: "__refresh__", label: m("", ctx, "tools.hub_refresh") });
  }
  options.push({ value: "", label: m("", ctx, "action.opt_back") });
  const hint = uninstall ? m("", ctx, "wizard.choose_hint") : m("", ctx, "tools.hub_pick_hint");
  const slug = await p.autocomplete({
    message: hint,
    placeholder: m("", ctx, "tools.hub_search_hint"),
    options
  });
  if (!slug || slug === "") return null;
  if (slug === "__refresh__") {
    restoreTerminalGap();
    await bridgeRunInteractive(root2, "tools-refresh");
    return pickTool(root2, await loadContext(root2), p, uninstall);
  }
  return slug;
}
async function pickToolAction(root2, ctx, p, toolName) {
  const menuMsg = mf("", ctx, "action.menu_teaser", toolName);
  await p.note(menuMsg, m("", ctx, "action.menu_title"));
  const slug = await p.select({
    message: m("", ctx, "action.menu_hint"),
    options: [
      { value: "install", label: m("", ctx, "action.opt_install") },
      { value: "uninstall", label: m("", ctx, "action.opt_uninstall") },
      { value: "check", label: m("", ctx, "action.opt_check") },
      { value: "reset", label: m("", ctx, "action.opt_reset") },
      { value: "back", label: m("", ctx, "action.opt_back") }
    ],
    initialValue: "install"
  });
  return slug === "back" ? null : slug;
}
async function runGameFlow(root2, ctx, p) {
  restoreTerminalGap();
  const readyCode = await bridgeRunInteractive(root2, "assess-ensure-ready");
  if (readyCode !== 0) return false;
  const slug = await pickTool(root2, ctx, p);
  if (!slug) return false;
  const tools = loadToolsList(root2);
  const tool = tools.find((t2) => t2.slug === slug);
  const toolName = tool?.name ?? slug;
  const action = await pickToolAction(root2, ctx, p, toolName);
  if (!action) return false;
  restoreTerminalGap();
  const code = await toolDispatch(root2, slug, action);
  return code === 0;
}
async function runUninstallFlow(root2, ctx, p) {
  const slug = await pickTool(root2, ctx, p, true);
  if (!slug) return false;
  restoreTerminalGap();
  const code = await toolDispatch(root2, slug, "uninstall");
  return code === 0;
}
async function afterInstallMenu(root2, p) {
  const ctx = await loadContext(root2);
  const pick = await p.select({
    message: m("", ctx, "install.after_title"),
    options: [
      { value: "menu", label: m("", ctx, "install.after_menu") },
      { value: "exit", label: m("", ctx, "install.after_exit") }
    ]
  });
  return pick === "exit" ? "exit" : "menu";
}
async function afterPcFixMenu(root2, p) {
  const ctx = await loadContext(root2);
  const pick = await p.select({
    message: m("", ctx, "assess.after_pc_title"),
    options: [
      { value: "install", label: m("", ctx, "assess.after_pc_install") },
      { value: "menu", label: m("", ctx, "assess.after_pc_menu") },
      { value: "exit", label: m("", ctx, "assess.after_pc_exit") }
    ]
  });
  return pick;
}
async function afterUninstallMenu(root2, p) {
  const ctx = await loadContext(root2);
  const pick = await p.select({
    message: m("", ctx, "wizard.after_uninstall_title"),
    options: [
      { value: "menu", label: m("", ctx, "wizard.after_uninstall_menu") },
      { value: "install", label: m("", ctx, "wizard.after_uninstall_install") },
      { value: "exit", label: m("", ctx, "wizard.after_uninstall_exit") }
    ]
  });
  return pick;
}
async function runSessionWelcome(root2, ctx, p) {
  await printBrandHeader(ctx);
  await p.intro(mf("", ctx, "wizard.intro", `v${ctx.runtime.version}`));
  if (!ctx.assess.systemReady) {
    await p.note(buildStyledStatusNote(ctx), m("", ctx, "wizard.status_title"));
  } else {
    const body = [
      `${iconOk()} ${styleSuccess(ctx.assess.hint)}`,
      "",
      styleMuted(m("", ctx, "runtime.intro_body"))
    ].join("\n");
    await p.note(body, m("", ctx, "runtime.intro_title"));
  }
  await p.pressContinue(m("", ctx, "ui.press_enter"), m("", ctx, "ui.ok_label"));
  restoreTerminalGap();
}
async function mainMenuLoop(root2, p) {
  let firstScreen = true;
  while (true) {
    const ctx = await loadContext(root2);
    if (firstScreen) {
      await runSessionWelcome(root2, ctx, p);
      firstScreen = false;
    } else {
      printMenuDivider();
    }
    const choice = await p.select({
      message: `${m("", ctx, "wizard.title")}
${styleHint(m("", ctx, "wizard.choose_hint"))}`,
      options: buildMenuOptions(ctx),
      initialValue: String(ctx.assess.recommended)
    });
    restoreTerminalGap();
    announceChoice(root2, choice);
    switch (choice) {
      case "1": {
        await bridgeRunInteractive(root2, "run-pc-fix");
        if (await runGameFlow(root2, ctx, p)) {
          const next = await afterInstallMenu(root2, p);
          if (next === "exit") {
            await p.outro(m("", ctx, "install.goodbye"));
            return;
          }
        }
        break;
      }
      case "2": {
        await bridgeRunInteractive(root2, "run-pc-fix");
        const next = await afterPcFixMenu(root2, p);
        if (next === "exit") {
          await p.outro(m("", ctx, "install.goodbye"));
          return;
        }
        if (next === "install" && await runGameFlow(root2, ctx, p)) {
          const after = await afterInstallMenu(root2, p);
          if (after === "exit") {
            await p.outro(m("", ctx, "install.goodbye"));
            return;
          }
        }
        break;
      }
      case "3": {
        if (await runGameFlow(root2, ctx, p)) {
          const next = await afterInstallMenu(root2, p);
          if (next === "exit") {
            await p.outro(m("", ctx, "install.goodbye"));
            return;
          }
        }
        break;
      }
      case "4": {
        restoreTerminalGap();
        await bridgeRunInteractive(root2, "print-status");
        restoreTerminalGap();
        break;
      }
      case "5": {
        if (await runUninstallFlow(root2, ctx, p)) {
          const next = await afterUninstallMenu(root2, p);
          if (next === "exit") return;
          if (next === "install" && await runGameFlow(root2, ctx, p)) {
            const after = await afterInstallMenu(root2, p);
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
async function runWizard(root2) {
  const wizardJs = (0, import_node_path2.join)(root2, "lib/prompter/dist/wizard.js");
  if (!(0, import_node_fs2.existsSync)(wizardJs)) {
    process.stderr.write(`wizard missing: ${wizardJs}
`);
    process.exit(2);
  }
  if (!hasInteractiveTty()) {
    const ctx2 = await loadContext(root2);
    process.stderr.write(`${m("", ctx2, "node.no_tty")}
`);
    process.exit(1);
  }
  const p = createCrkcachyPrompter();
  let ctx = await loadContext(root2);
  if (!ctx.runtime.nodeOk) {
    process.stderr.write("Node.js 18+ required to run wizard.\n");
    process.exit(1);
  }
  try {
    await ensureGlowRuntime(root2, ctx, p);
    ctx = await loadContext(root2);
    await runPreflightGates(root2, ctx, p);
    await mainMenuLoop(root2, p);
  } catch (err) {
    if (err instanceof WizardCancelledError) {
      process.exit(1);
    }
    const msg = err instanceof Error ? err.message : String(err);
    process.stderr.write(`${msg}
`);
    process.exit(1);
  }
}
var { root } = parseArgs(process.argv);
runWizard(root);
