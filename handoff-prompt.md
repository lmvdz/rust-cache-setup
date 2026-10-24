# Handoff prompt

Adapt this kit to the Rust repository you are working in. First inspect its operating system, Rust toolchain, existing Cargo configuration, wrapper environment variables, available disk budget, and authorization to install tools. Preserve existing project instructions and explain concrete changes.

Use pinned kache 1.2.2 as the default. Copy the local-only bounded example after reviewing the budget. Keep executable caching disabled in conservative examples, especially Windows. Use the helper matching the shell; PowerShell requires 7.5+ and callers must inspect LASTEXITCODE. Preserve argument boundaries, clear both compiler and workspace wrapper conflicts from environment and inherited Cargo config, disable incremental compilation, and restore the caller's environment. Caller --config wrapper overrides must be excluded or explicitly handled.

Treat cargo-reapi 0.2.0 as an optional Unix-only local cache alternative. Reject reapi on Windows; do not try an experimental main-branch installation to bypass that limitation. Require an explicit local cache directory. Never silently enable remote execution, upload credentials, or assume the caches share entries. Document separate disk management for reapi.

Validate helper dispatch and environment restoration with stub tests. If authorized, verify real cache reuse on a small isolated project: cold build, record statistics, clean only that project's target, and repeat. A fresh Cargo invocation without cleaning is not evidence of a compiler cache hit. Record versions and limitations. Keep global settings untouched unless authorized. Finish with the files changed and checks performed.
