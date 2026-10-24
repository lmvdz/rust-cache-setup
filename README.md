# Rust build cache setup

A small, portable starting kit for local Rust compiler caching. Default to **kache 1.2.2**. The optional **cargo-reapi 0.2.0** local cache requires a supported Unix backend (verify it on your host); it does not provide a supported strict local-cache backend on Windows. The helpers fail clearly if reapi is selected on Windows.

## Quick start

Install the default wrapper (requires Rust and Cargo):

```sh
cargo install kache --version 1.2.2 --locked
```

Copy both `scripts/` and `configs/` into your Rust repository. Review the 4 GiB disk budget in the example and helper overrides. The helper selects the bundled example by absolute path, isolates host configuration, clears inherited KACHE settings, and uses a local store under LOCALAPPDATA (Windows) or XDG_CACHE_HOME / ~/.cache. Run from the repository root:

```sh
bash scripts/cargo-cached.sh check
CARGO_CACHE_MODE=none bash scripts/cargo-cached.sh test
```

On Windows, use **PowerShell 7.5 or later**:

```powershell
& ./scripts/cargo-cached.ps1 check
$env:CARGO_CACHE_MODE = 'none'
& ./scripts/cargo-cached.ps1 test
Remove-Item Env:CARGO_CACHE_MODE
```

The PowerShell helper sets `$LASTEXITCODE` to Cargo's exit status; automation should check it or explicitly `exit $LASTEXITCODE`. Invoke the script with `&`, and execute the Bash script instead of sourcing it. Helpers preserve Cargo arguments, replace inherited wrapper choices, suppress workspace wrappers, disable incremental compilation, and leave the calling environment intact. They do not edit global Cargo configuration. Caller-provided `--config` wrapper overrides are outside this guarantee: do not supply them.

## Verify caching

Run `kache doctor` and `kache stats`. Build a small representative project through the helper, record stats, run `cargo clean` for that test project, and rebuild the same command. Look for a cold miss followed by a cache hit. A second Cargo invocation without cleaning can be merely Cargo freshness and does not prove a cache hit. Do not clean a shared active target directory. kache 1.2.2 was independently checked on Windows with a cold miss followed by a hit; this kit's tests exercise dispatch, argument handling, and environment behavior using stubs, without compiling.

Executable caching stays disabled in the conservative example, including on Windows. This reduces coverage but avoids changing the platform's safer default. Cache correctness still depends on build inputs being declared correctly. Review upstream behavior before enabling executable caching or introducing a fallback wrapper.

## Optional Unix local cache

Use this only after measuring redundant compilation and confirming the host supports the backend:

```sh
cargo install cargo-reapi --version 0.2.0 --locked
export CARGO_REAPI_CACHE_DIR="$HOME/.cache/cargo-reapi"
CARGO_CACHE_MODE=reapi bash scripts/cargo-cached.sh check
```

This selects the local cache backend, never remote execution. The stores and cache keys of kache and cargo-reapi are independent. See `configs/cargo-reapi-env.example`. Inspect the selected release's `cargo reapi --help` and diagnostic commands before rollout. No experimental main-branch installation is required or recommended here. Reapi cache storage needs separate disk management; the bounded kache example does not bound it.

## Contents and checks

`AGENTS.md` contains copyable agent instructions. `handoff-prompt.md` helps adapt this kit. Config examples contain no credentials or remote storage settings.

```powershell
pwsh -NoProfile -File tests/helpers.Tests.ps1
```

```sh
bash -n scripts/cargo-cached.sh
bash tests/helpers.test.sh
```

Upstream references: [kache 1.2.2 configuration](https://github.com/kunobi-ninja/kache/blob/v1.2.2/docs/getting-started/configuration.mdx), [cargo-reapi 0.2.0 source](https://docs.rs/crate/cargo-reapi/0.2.0/source/). Versions are deliberately pinned; review changes before updating. This repository does not include a license grant; obtain permission before redistributing code under a chosen license.
