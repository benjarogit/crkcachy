#!/usr/bin/env bash
# Tool catalog – index from GitHub + local, metadata from tool.json

set -euo pipefail

CRKCACHY_REPO_URL="${CRKCACHY_REPO_URL:-https://github.com/benjarogit/crkcachy.git}"
CRKCACHY_REPO_BRANCH="${CRKCACHY_REPO_BRANCH:-main}"
CRKCACHY_CACHE_ROOT="${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}"
CRKCACHY_TOOLS_CACHE="${CRKCACHY_TOOLS_CACHE:-${CRKCACHY_CACHE_ROOT}/repo}"

# Populated by tool_catalog_refresh
TOOL_CATALOG_SLUGS=()
TOOL_CATALOG_SOURCES=()   # bundled | cached | remote
TOOL_CATALOG_INSTALLS=()  # path to install.sh or empty for remote-only

tool_catalog_lang() {
  echo "${CRKCACHY_LANG:-de}"
}

tool_catalog_json_field() {
  local file="$1"
  local jq_expr="$2"
  python3 - "$file" "$jq_expr" <<'PY'
import json, sys
path, expr = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except (OSError, json.JSONDecodeError):
    print("")
    sys.exit(0)
cur = data
for part in expr.split("."):
    if not part:
        continue
    if isinstance(cur, dict):
        cur = cur.get(part, "")
    else:
        cur = ""
        break
if cur is None:
    cur = ""
print(cur if isinstance(cur, (str, int, float)) else "")
PY
}

tool_meta_path() {
  local tool_dir="$1"
  echo "${tool_dir}/tool.json"
}

tool_read_meta_field() {
  local tool_dir="$1"
  local field="$2"
  local lang
  local meta

  meta="$(tool_meta_path "$tool_dir")"
  [[ -f "$meta" ]] || return 1
  lang="$(tool_catalog_lang)"

  if [[ "$field" == "name" || "$field" == "description" ]]; then
    tool_catalog_json_field "$meta" "${field}.${lang}"
    return 0
  fi

  tool_catalog_json_field "$meta" "$field"
}

tool_index_local_path() {
  echo "${CRKCACHY_ROOT}/tools/index.json"
}

tool_index_cache_path() {
  echo "${CRKCACHY_TOOLS_CACHE}/tools/index.json"
}

tool_catalog_fetch_index() {
  local dest="${CRKCACHY_CACHE_ROOT}/index.json"
  local raw_url

  mkdir -p "${CRKCACHY_CACHE_ROOT}"
  raw_url="https://raw.githubusercontent.com/benjarogit/crkcachy/${CRKCACHY_REPO_BRANCH}/tools/index.json"

  if command_exists curl; then
    if curl -fsSL --max-time 20 "$raw_url" -o "${dest}.tmp" 2>/dev/null; then
      mv -f "${dest}.tmp" "$dest"
      echo "$dest"
      return 0
    fi
    rm -f "${dest}.tmp"
  fi

  if [[ -f "$(tool_index_local_path)" ]]; then
    echo "$(tool_index_local_path)"
    return 0
  fi

  return 1
}

tool_catalog_index_path() {
  local cached="${CRKCACHY_CACHE_ROOT}/index.json"
  local local_index bundled

  bundled="$(tool_index_local_path)"
  if [[ -f "$cached" ]]; then
    echo "$cached"
    return 0
  fi
  if [[ -f "$bundled" ]]; then
    echo "$bundled"
    return 0
  fi
  tool_catalog_fetch_index || return 1
}

tool_catalog_index_slugs() {
  local index_path="$1"
  python3 - "$index_path" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)
    for t in data.get("tools", []):
        slug = t.get("slug")
        if slug:
            print(slug)
except (OSError, json.JSONDecodeError):
    pass
PY
}

tool_catalog_index_meta() {
  local index_path="$1"
  local slug="$2"
  local field="$3"
  local lang
  lang="$(tool_catalog_lang)"
  python3 - "$index_path" "$slug" "$field" "$lang" <<'PY'
import json, sys
path, slug, field, lang = sys.argv[1:5]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    for t in data.get("tools", []):
        if t.get("slug") == slug:
            val = t.get(field, {})
            if isinstance(val, dict):
                print(val.get(lang, val.get("en", "")))
            else:
                print(val)
            break
except (OSError, json.JSONDecodeError):
    pass
PY
}

tool_resolve_tool_dir() {
  local slug="$1"
  local bundled cached

  bundled="${CRKCACHY_ROOT}/tools/${slug}"
  if [[ -f "${bundled}/install.sh" ]]; then
    echo "$bundled"
    return 0
  fi

  cached="${CRKCACHY_TOOLS_CACHE}/tools/${slug}"
  if [[ -f "${cached}/install.sh" ]]; then
    echo "$cached"
    return 0
  fi

  return 1
}

tool_resolve_install_path() {
  local slug="$1"
  local dir
  dir="$(tool_resolve_tool_dir "$slug")" || return 1
  echo "${dir}/install.sh"
}

tool_source_for_slug() {
  local slug="$1"
  if [[ -f "${CRKCACHY_ROOT}/tools/${slug}/install.sh" ]]; then
    echo "bundled"
    return 0
  fi
  if [[ -f "${CRKCACHY_TOOLS_CACHE}/tools/${slug}/install.sh" ]]; then
    echo "cached"
    return 0
  fi
  echo "remote"
}

tool_catalog_refresh() {
  local index_path slug dir install source
  local -a slugs_from_index=()
  local -a slugs_from_disk=()

  TOOL_CATALOG_SLUGS=()
  TOOL_CATALOG_SOURCES=()
  TOOL_CATALOG_INSTALLS=()

  if index_path="$(tool_catalog_index_path 2>/dev/null)"; then
    while IFS= read -r slug; do
      [[ -n "$slug" ]] && slugs_from_index+=("$slug")
    done < <(tool_catalog_index_slugs "$index_path")
  fi

  if [[ -d "${CRKCACHY_ROOT}/tools" ]]; then
    for install in "${CRKCACHY_ROOT}/tools"/*/install.sh; do
      [[ -f "$install" ]] || continue
      slug="$(basename "$(dirname "$install")")"
      slugs_from_disk+=("$slug")
    done
  fi

  if [[ -d "${CRKCACHY_TOOLS_CACHE}/tools" ]]; then
    for install in "${CRKCACHY_TOOLS_CACHE}/tools"/*/install.sh; do
      [[ -f "$install" ]] || continue
      slug="$(basename "$(dirname "$install")")"
      slugs_from_disk+=("$slug")
    done
  fi

  # Merge: index order first, then any local-only folders
  for slug in "${slugs_from_index[@]}"; do
    [[ -n "$slug" ]] || continue
    TOOL_CATALOG_SLUGS+=("$slug")
    source="$(tool_source_for_slug "$slug")"
    TOOL_CATALOG_SOURCES+=("$source")
    if dir="$(tool_resolve_tool_dir "$slug" 2>/dev/null)"; then
      TOOL_CATALOG_INSTALLS+=("${dir}/install.sh")
    else
      TOOL_CATALOG_INSTALLS+=("")
    fi
  done

  for slug in "${slugs_from_disk[@]}"; do
    [[ -n "$slug" ]] || continue
    found=false
    for s in "${TOOL_CATALOG_SLUGS[@]}"; do
      [[ "$s" == "$slug" ]] && found=true && break
    done
    [[ "$found" == true ]] && continue
    TOOL_CATALOG_SLUGS+=("$slug")
    TOOL_CATALOG_SOURCES+=("$(tool_source_for_slug "$slug")")
    TOOL_CATALOG_INSTALLS+=("$(tool_resolve_install_path "$slug")")
  done

  tool_catalog_sort_by_name

  [[ ${#TOOL_CATALOG_SLUGS[@]} -gt 0 ]]
}

tool_catalog_sort_by_name() {
  [[ ${#TOOL_CATALOG_SLUGS[@]} -le 1 ]] && return 0

  local lang lc i name
  local -a order=() sorted_slugs=() sorted_sources=() sorted_installs=()

  lang="$(tool_catalog_lang)"
  lc="${lang}_UTF-8"
  if ! locale -a 2>/dev/null | LC_ALL=C grep -qxF "$lc"; then
    lc="C.UTF-8"
  fi

  while IFS=$'\t' read -r _name idx; do
    [[ -n "${idx:-}" ]] && order+=("$idx")
  done < <(
    for i in "${!TOOL_CATALOG_SLUGS[@]}"; do
      name="$(tool_catalog_get_name "${TOOL_CATALOG_SLUGS[$i]}")"
      name="${name//$'\t'/ }"
      name="${name//$'\n'/ }"
      printf '%s\t%s\n' "$name" "$i"
    done | LC_COLLATE="$lc" sort -f -t $'\t' -k1,1
  )

  for i in "${order[@]}"; do
    sorted_slugs+=("${TOOL_CATALOG_SLUGS[$i]}")
    sorted_sources+=("${TOOL_CATALOG_SOURCES[$i]}")
    sorted_installs+=("${TOOL_CATALOG_INSTALLS[$i]}")
  done

  TOOL_CATALOG_SLUGS=("${sorted_slugs[@]}")
  TOOL_CATALOG_SOURCES=("${sorted_sources[@]}")
  TOOL_CATALOG_INSTALLS=("${sorted_installs[@]}")
}

tool_catalog_get_name() {
  local slug="$1"
  local dir index_path name

  if dir="$(tool_resolve_tool_dir "$slug" 2>/dev/null)"; then
    name="$(tool_read_meta_field "$dir" name 2>/dev/null || true)"
    [[ -n "$name" ]] && echo "$name" && return 0
  fi

  if index_path="$(tool_catalog_index_path 2>/dev/null)"; then
    name="$(tool_catalog_index_meta "$index_path" "$slug" name)"
    [[ -n "$name" ]] && echo "$name" && return 0
  fi

  local key val
  key="tool.${slug}.name"
  val="${_MSG[$key]:-}"
  [[ -n "$val" ]] && echo "$val" || echo "$slug"
}

tool_catalog_get_desc() {
  local slug="$1"
  local dir index_path desc

  if dir="$(tool_resolve_tool_dir "$slug" 2>/dev/null)"; then
    desc="$(tool_read_meta_field "$dir" description 2>/dev/null || true)"
    [[ -n "$desc" ]] && echo "$desc" && return 0
  fi

  if index_path="$(tool_catalog_index_path 2>/dev/null)"; then
    desc="$(tool_catalog_index_meta "$index_path" "$slug" description)"
    [[ -n "$desc" ]] && echo "$desc" && return 0
  fi

  local key
  key="tool.${slug}.desc"
  echo "${_MSG[$key]:-}"
}

tool_catalog_status_label() {
  local source="$1"
  case "$source" in
    bundled) echo "$(msg tools.status_bundled)" ;;
    cached) echo "$(msg tools.status_cached)" ;;
    remote) echo "$(msg tools.status_remote)" ;;
    *) echo "" ;;
  esac
}
