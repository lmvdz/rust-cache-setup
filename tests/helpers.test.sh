#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/cargo" <<'STUB'
#!/usr/bin/env bash
if [[ $RUSTC_WRAPPER == kache ]]; then
  [[ $KACHE_LOCAL_ONLY == 1 && $KACHE_CACHE_EXECUTABLES == 0 && -z ${KACHE_REMOTE_URL-} ]] || exit 90
fi
printf '%s\n' "${RUSTC_WRAPPER-unset}" "${RUSTC_WORKSPACE_WRAPPER-unset}" "${CARGO_BUILD_RUSTC_WRAPPER-unset}" "${CARGO_BUILD_RUSTC_WORKSPACE_WRAPPER-unset}" "${CARGO_INCREMENTAL-unset}" "$@" > "$CAPTURE"
exit 17
STUB
printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/kache"
chmod +x "$tmp/cargo" "$tmp/kache"
export PATH="$tmp:$PATH" CAPTURE="$tmp/result"
export KACHE_REMOTE_URL=sentinel-private-remote KACHE_LOCAL_ONLY=0
export RUSTC_WRAPPER=old RUSTC_WORKSPACE_WRAPPER=old CARGO_BUILD_RUSTC_WRAPPER=old CARGO_BUILD_RUSTC_WORKSPACE_WRAPPER=old CARGO_INCREMENTAL=1
for mode in kache none off disabled; do
  set +e
  CARGO_CACHE_MODE="$mode" bash "$root/scripts/cargo-cached.sh" test -p 'crate with spaces' -- --literal
  result=$?
  set -e
  [[ $result == 17 ]]
  wrapper=''; [[ $mode != kache ]] || wrapper=kache
  printf '%s\n' "$wrapper" '' "$wrapper" '' 0 test -p 'crate with spaces' -- --literal > "$tmp/expected"
  diff -u "$tmp/expected" "$CAPTURE"
  [[ $RUSTC_WRAPPER == old && $CARGO_INCREMENTAL == 1 ]]
done
if CARGO_CACHE_MODE=bad bash "$root/scripts/cargo-cached.sh" check; then exit 1; fi
if OSTYPE=msys CARGO_CACHE_MODE=reapi bash "$root/scripts/cargo-cached.sh" check; then exit 1; fi
OSTYPE=linux-gnu CARGO_CACHE_MODE=reapi CARGO_REAPI_CACHE_DIR='/local cache' bash "$root/scripts/cargo-cached.sh" check || result=$?
[[ $result == 17 ]]
printf '%s\n' '' '' '' '' 0 reapi --backend cache --cache-dir '/local cache' -- check > "$tmp/expected"
diff -u "$tmp/expected" "$CAPTURE"
echo 'Bash helper checks passed.'
