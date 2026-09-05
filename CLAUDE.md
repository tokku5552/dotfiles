# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles. The repo is not code that runs; it is a collection of config
files that get symlinked into `$HOME` (and a few well-known subpaths) by install
scripts. Every "build" here is really `ln -sf` from `~/dotfiles/<subdir>/<file>`
to its canonical location, so edits to tracked files take effect immediately
after the links exist.

## Install & setup commands

Top-level `Makefile` only wraps the two most-used scripts:

- `make link` — runs `link.sh`. Symlinks zsh configs, `mise/config.toml` (to
  `~/.config/mise/config.toml`), and `ccstatusline/settings.json` into their
  expected paths. Before overwriting, it backs up each existing target into
  `~/.dotfiles_backup_<timestamp>/`.
- `make brew` — runs `brew.sh` (`brew doctor` → `update` → `upgrade` →
  `bundle --file .Brewfile` → `cleanup`). The `.Brewfile` is the source of
  truth for formulae/casks/taps; dump with `brew bundle dump --global`.

Per-tool installers are **not** in the Makefile and must be invoked directly:

- `bash claude/install.sh` — links `claude/CLAUDE.md` and `claude/scripts/` into
  `~/.claude/`, then calls `claude/sync.sh --merge` to **generate**
  `~/.claude/settings.json` from `claude/settings.json` plus this machine's
  `claude/settings.local.json`. That file is not a symlink (see below). On the
  first run only — while no snapshot exists — it copies the live settings to
  `settings.json.bak`. Exits non-zero and writes nothing on a merge conflict.
- `bash claude/sync.sh` — reconciles Claude Code's own write-backs with the
  tracked base. No args reports drift (exit 3 if any); `--merge` regenerates the
  live settings; `--apply` first persists this machine's drift into the base or
  the overlay. Run it before opening a PR. `--prefer-local` resolves conflicts,
  `-n` is a dry run.
- `bash codex/install.sh` — registers MCP servers via `codex mcp add` and links
  `codex/AGENTS.md` into `~/.codex/`.
- `bash gemini/install.sh` — `npm install -g @google/gemini-cli`, then links
  `gemini/commands` and `gemini/GEMINI.md` into `~/.gemini/`.
- `bash VSCode/install_extension.sh` (macOS/Linux) or
  `powershell -File VSCode/install_extension.ps1` (Windows) — installs VS Code
  extensions listed in `VSCode/extensions`. Export the current list with
  `code --list-extensions > VSCode/extensions`.

Syntax-check shell scripts with `zsh -n zsh/.zshrc` or `shellcheck brew.sh
link.sh` when touching them — there is no test suite.

## Layout & what lives where

- `zsh/` — shell config (`.zshrc`, `.zshenv`, `.zprofile`, `.zpreztorc`, etc.).
  Uses **prezto** as the framework (sourced from `~/.zprezto/init.zsh`).
- `mise/config.toml`, `.Brewfile`, `brew.sh` — package/runtime management
  (mise handles language version management; `legacy_version_file` is enabled
  via `idiomatic_version_file_enable_tools` for `node` and `python`).
- `claude/` — Claude Code config:
  - `settings.json` — the shared base (hooks, permissions, plugins,
    marketplaces). Tracked.
  - `settings.local.json` — this machine's overlay. **Gitignored**; seed it from
    `settings.local.json.example` (tracked).
  - `sync.sh` — merges base + overlay, detects drift, persists it. The only
    place that computes settings.
  - `install.sh` — links `CLAUDE.md`/`scripts/` and calls `sync.sh --merge`.
  - `CLAUDE.md` — global user instructions, not repo instructions.
  - `scripts/` — hook implementations.
  - `~/.claude/settings.json` and `~/.claude/.settings.snapshot.json` are
    generated; neither lives in this repo.
- `codex/`, `gemini/`, `ccstatusline/` — config + install scripts for other AI
  CLIs / the Claude Code status line.
- `VSCode/` — `settings.json`, the `extensions` list, and install scripts.
- `.mcp.json` — project-scoped MCP server declarations (gemini-cli, codex).
- `AGENTS.md` — contributor guide (commits, style, testing). Read it before
  proposing changes to conventions.
- `docs/claude-settings-runbook.md` — migration, day-to-day and troubleshooting
  procedures for the settings split, plus the reasoning behind its design. Read
  it before changing `claude/sync.sh` or advising on a migration.

## Local (gitignored) overrides

`zsh/.zshrc.local` and `zsh/.zshenv.local` are sourced by `.zshrc`/`.zshenv` but
excluded via `.gitignore`. They are the correct place for machine-specific
aliases, PATH additions, and secrets (API keys, tokens). Copy from the matching
`*.example` to seed them. **Never** move secrets into tracked files.

`claude/settings.local.json` is the same idea for Claude Code, but it is applied
by merging rather than sourcing — see the next section. The routing rule that
keeps it useful: **any key Claude Code writes back on its own belongs in the
overlay**, listed in `LOCAL_KEYS` in `claude/sync.sh`. An unlisted key that the
tool rewrites gets persisted into the tracked base and starts conflicting across
machines, which is the failure this whole arrangement exists to prevent.

Do not confuse it with the repository's own `.claude/settings.local.json`, which
is Claude Code's project-scoped settings file and *is* tracked.

## Claude Code settings (`claude/settings.json`)

This is the **shared base**, not the file Claude Code reads. Edits here reach
this machine only after `claude/install.sh` (or `claude/sync.sh --merge`)
regenerates `~/.claude/settings.json` from base + `settings.local.json`.

**Never hand-edit `~/.claude/settings.json`** — it is generated and is rewritten
on every merge. Claude Code itself writes to it constantly (that is the point of
`sync.sh`), so put deliberate changes in the base or the overlay instead.

Notable pieces:

- `permissions.deny` — hard-blocks destructive Bash patterns (`rm -rf /*`,
  `git push --force *`, `gh pr merge *`, etc.) and sensitive reads (`.env`,
  `~/.ssh/**`, `~/.aws/**`). The `deny-check.sh` hook below enforces these at
  runtime in addition to the harness's own checks.
- `permissions.ask` — prompts for `curl`/`wget`/`bash -c`/`sh -c`.
- `hooks.PreToolUse` (matcher `Bash`) runs two scripts from
  `claude/scripts/` on every Bash tool call:
  - `deny-check.sh` reads the `permissions.deny` list, splits the command on
    `;`, `&&`, `||`, and **blocks (exit 2)** any segment matching a
    `Bash(<glob>)` pattern. It reads `~/.claude/settings.json`, i.e. the
    generated file — so `sync.sh` refuses to install a result that has an empty
    `permissions.deny` or that no longer runs this hook.
  - `audit-log.py` appends every command to `~/.claude/audit.log` with a UTC
    timestamp. Purely observational (always exits 0).
- `enabledPlugins` + `extraKnownMarketplaces` wire in plugins from
  `openai/codex-plugin-cc` and `tokku5552/cc-plugins`. These are the keys most
  likely to differ per machine, so they are in `LOCAL_KEYS` and drift on them
  lands in the overlay.

When adding a new deny pattern, the glob form `Bash(<pattern>)` is what
`deny-check.sh` parses — keep that shape. When adding a new hook script, place
it under `claude/scripts/` (symlinked as a directory) and make it executable;
`install.sh` chmods `*.sh` but not other extensions.

## Conventions

- Commits follow **Conventional Commits** (`feat:`, `fix:`, `chore:`, `docs:`).
  Keep changes narrow — don't mix zsh, VSCode, and Homebrew edits into one PR.
- Shell scripts: `#!/bin/sh` with `set -euo pipefail` when bash-only features
  are needed; otherwise POSIX-portable. Filenames lowercase-with-hyphens;
  dotfiles mirror their upstream names.
- Before running `link.sh` or any `install.sh` on a new machine, skim the
  targets — these scripts overwrite with `ln -sf`, and while `link.sh` takes
  backups, the per-tool installers only back up specific files.
