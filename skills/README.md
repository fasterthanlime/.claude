# Claude Code Skills

Personal skills for [Claude Code](https://claude.ai/code).

## What are Skills?

Skills are modular capabilities that extend Claude's functionality. They're directories containing a `SKILL.md` (or standalone `.md` files) with instructions that Claude reads when relevant to your task.

Unlike slash commands which you invoke explicitly, skills are **model-invoked** — Claude autonomously decides when to use them based on your request and the skill's description.

## Locations

Skills can live in three places:

| Location | Scope |
|----------|-------|
| `~/.claude/skills/` | Personal (this repo) |
| `.claude/skills/` | Per-project |
| Plugins | Bundled with plugins |

## Documentation

See the official spec: <https://docs.anthropic.com/en/docs/claude-code/skills>

## Skills in this repo

### Meta

- **[skill-creator](./skill-creator/)** — Guide for creating effective skills

### Rust Development

- **[facet](./facet/)** — Facet: serde replacement library (crate mappings, usage patterns)
- **[rustc-timings](./rustc-timings/)** — Profile compile times with `-Zself-profile` and DuckDB (includes `profile-crate.sh`)
- **[rustc-bloat](./rustc-bloat/)** — Find binary bloat with `cargo-llvm-lines`, `-Zprint-type-sizes`

### Debugging

- **[valgrind](./valgrind/)** — Memory debugging and callgrind profiling (Linux)
- **[cranelift-debugging](./cranelift-debugging/)** — Debug JIT code: cdb.exe (Windows), SIGSEGV handlers (Unix), ABI issues (includes `sigsegv_handler.rs`)
- **[nextest-scripts](./nextest-scripts/)** — Wrapper and setup scripts for cargo-nextest (includes example wrappers + `nextest.toml`)

### Resource Management

- **[systemd-run](./systemd-run/)** — Limit memory/CPU for tests with systemd cgroups

### GitHub

- **[gh-cli](./gh-cli/)** — GitHub CLI workflows for issues, PRs, CI checks, and branch management
