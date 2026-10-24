# Agent instructions: local Rust build caching

Default to kache 1.2.2. Install only if authorized with `cargo install kache --version 1.2.2 --locked`. Copy the scripts and configs directories together; review the bundled example and helper disk limit overrides. Run helpers from that repository's root:

- Bash: `bash scripts/cargo-cached.sh check`
- PowerShell 7.5+: `& ./scripts/cargo-cached.ps1 check`; inspect `$LASTEXITCODE`.
- Set `CARGO_CACHE_MODE=none` (or `off`) to run without compiler caching.

The helpers override inherited `RUSTC_WRAPPER`, `RUSTC_WORKSPACE_WRAPPER`, `CARGO_BUILD_RUSTC_WRAPPER`, and `CARGO_BUILD_RUSTC_WORKSPACE_WRAPPER`, and disable incremental compilation. Do not pass Cargo `--config` wrapper overrides. Execute the Bash helper; do not source it. PowerShell restores the environment when it returns. Do not edit global configuration without explicit authorization.

Optional cargo-reapi 0.2.0 local cache mode requires a Unix host. It has no supported Windows strict local-cache backend; the helpers reject that combination. On a suitable host, install with `cargo install cargo-reapi --version 0.2.0 --locked`, set `CARGO_REAPI_CACHE_DIR` to a local directory, and select `CARGO_CACHE_MODE=reapi`. This is an explicit alternative, not an automatic recommendation for parallel work. Measure first and manage its disk usage separately. Do not install experimental main-branch code or enable remote uploads as part of this kit.

Verify with `kache doctor`, `kache stats`, and an isolated cold build / clean / repeat build. Confirm cache counters show a miss and then a hit; Cargo freshness alone proves nothing. Never clean an active shared target. The two caches have independent keys and stores. Preserve the example's disabled executable caching unless upstream guidance and representative tests justify changing it.

When changing this kit, run its PowerShell and Bash stub tests. Keep public examples portable and free of private paths, credentials, build outputs, and tracker data. Do not add a license without the owner's decision.
