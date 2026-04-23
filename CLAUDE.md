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

- `make link` — runs `link.sh`. Symlinks zsh configs, `asdf/.asdfrc`, and
  `ccstatusline/settings.json` into their expected paths. Before overwriting, it
  backs up each existing target into `~/.dotfiles_backup_<timestamp>/`.
- `make brew` — runs `brew.sh` (`brew doctor` → `update` → `upgrade` →
  `bundle --file .Brewfile` → `cleanup`). The `.Brewfile` is the source of
  truth for formulae/casks/taps; dump with `brew bundle dump --global`.

Per-tool installers are **not** in the Makefile and must be invoked directly:

- `bash claude/install.sh` — links `claude/CLAUDE.md`, `claude/settings.json`,
  and `claude/scripts/` into `~/.claude/`. Backs up any pre-existing real file
  (non-symlink) to `*.bak` before replacing.
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
- `asdf/.asdfrc`, `.Brewfile`, `brew.sh` — package/runtime management.
- `claude/` — Claude Code config: `settings.json` (hooks, permissions, enabled
  plugins, marketplaces), `CLAUDE.md` (global user instructions, not repo
  instructions), and `scripts/` containing hook implementations.
- `codex/`, `gemini/`, `ccstatusline/` — config + install scripts for other AI
  CLIs / the Claude Code status line.
- `VSCode/` — `settings.json`, the `extensions` list, and install scripts.
- `.mcp.json` — project-scoped MCP server declarations (gemini-cli, codex).
- `AGENTS.md` — contributor guide (commits, style, testing). Read it before
  proposing changes to conventions.

## Local (gitignored) overrides

`zsh/.zshrc.local` and `zsh/.zshenv.local` are sourced by `.zshrc`/`.zshenv` but
excluded via `.gitignore`. They are the correct place for machine-specific
aliases, PATH additions, and secrets (API keys, tokens). Copy from the matching
`*.example` to seed them. **Never** move secrets into tracked files.

## Claude Code settings (`claude/settings.json`)

Anything edited here affects every Claude Code session on this machine once
`claude/install.sh` has run, because the file is symlinked to
`~/.claude/settings.json`. Notable pieces:

- `permissions.deny` — hard-blocks destructive Bash patterns (`rm -rf /*`,
  `git push --force *`, `gh pr merge *`, etc.) and sensitive reads (`.env`,
  `~/.ssh/**`, `~/.aws/**`). The `deny-check.sh` hook below enforces these at
  runtime in addition to the harness's own checks.
- `permissions.ask` — prompts for `curl`/`wget`/`bash -c`/`sh -c`.
- `hooks.PreToolUse` (matcher `Bash`) runs two scripts from
  `claude/scripts/` on every Bash tool call:
  - `deny-check.sh` reads the `permissions.deny` list, splits the command on
    `;`, `&&`, `||`, and **blocks (exit 2)** any segment matching a
    `Bash(<glob>)` pattern.
  - `audit-log.py` appends every command to `~/.claude/audit.log` with a UTC
    timestamp. Purely observational (always exits 0).
- `enabledPlugins` + `extraKnownMarketplaces` wire in plugins from
  `openai/codex-plugin-cc` and `tokku5552/cc-plugins`.

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
