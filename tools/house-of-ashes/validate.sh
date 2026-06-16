#!/usr/bin/env bash
# Deprecated – use check.sh (./install.sh --check)

exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check.sh" "$@"
