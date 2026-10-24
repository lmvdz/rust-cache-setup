#!/usr/bin/env bash
# Execute this script; do not source it. Changes stay in the child process.
set -euo pipefail
mode="${CARGO_CACHE_MODE:-kache}"
case "$mode" in
  kache|reapi|none|off|disabled) ;;
  *) echo "Unknown CARGO_CACHE_MODE='$mode'; use kache, reapi, or none." >&2; exit 2 ;;
esac
if [[ "$mode" == reapi ]]; then
  case "${OSTYPE:-}" in msys*|cygwin*|win*) echo 'cargo-reapi 0.2.0 local cache requires Unix; use kache on Windows.' >&2; exit 2 ;; esac
  : "${CARGO_REAPI_CACHE_DIR:?Set CARGO_REAPI_CACHE_DIR to a local cache directory}"
fi
# Empty environment overrides suppress inherited Cargo configuration too.
export RUSTC_WRAPPER='' RUSTC_WORKSPACE_WRAPPER=''
export CARGO_BUILD_RUSTC_WRAPPER='' CARGO_BUILD_RUSTC_WORKSPACE_WRAPPER=''
export CARGO_INCREMENTAL=0
case "$mode" in
  kache)
    command -v kache >/dev/null || { echo 'Install kache 1.2.2 first (see README).' >&2; exit 127; }
    kit_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cache_root="${LOCALAPPDATA:-${XDG_CACHE_HOME:-$HOME/.cache}}/rust-cache-setup"
    mkdir -p "$cache_root/cache" "$cache_root/runtime"
    while IFS= read -r name; do unset "$name"; done < <(compgen -e | LC_ALL=C sort | sed -n '/^KACHE_/p')
    native_path() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
    export KACHE_CONFIG="$(native_path "$kit_root/configs/.kache.toml.example")"
    export KACHE_HOST_CONFIG="$(native_path "$kit_root/configs/kache-host.toml")"
    export KACHE_CACHE_DIR="$(native_path "$cache_root/cache")"
    export KACHE_RUNTIME_DIR="$(native_path "$cache_root/runtime")"
    export KACHE_LOCAL_ONLY=1 KACHE_MAX_SIZE=4GiB KACHE_CACHE_EXECUTABLES=0 KACHE_DISABLED=0
    export RUSTC_WRAPPER=kache CARGO_BUILD_RUSTC_WRAPPER=kache
    exec cargo "$@" ;;
  reapi)
    exec cargo reapi --backend cache --cache-dir "$CARGO_REAPI_CACHE_DIR" -- "$@" ;;
  *) exec cargo "$@" ;;
esac
