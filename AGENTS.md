# Repository Guidelines

## Project Structure & Module Organization
- Root: setup scripts and configs — `.Brewfile`, `Makefile`, `brew.sh`, `link.sh`, `README.md`.
- `zsh/`: shell configuration (`.zshrc`, `.zshenv`, prezto config) plus `*.local.example` templates for private overrides.
- `VSCode/`: `settings.json`, `extensions` list, and install scripts (`install_extension.sh`, `install_extension.ps1`).
- `mise/`: version manager config (`config.toml`).
- `claude/`: Claude Code config. `settings.json` is the shared base;
  `settings.local.json` (gitignored, seeded from `settings.local.json.example`)
  holds this machine's overrides; `sync.sh` merges the two into
  `~/.claude/settings.json` and reconciles what Claude Code writes back;
  `scripts/` holds the hook implementations.

## Build, Test, and Development Commands
- `make link`: creates symlinks from this repo into `$HOME` (see `link.sh`).
- `make brew`: validates/updates Homebrew and installs from `.Brewfile` via `brew bundle`.
- VS Code extensions (macOS/Linux): `bash VSCode/install_extension.sh`.
- VS Code extensions (Windows): `powershell -File VSCode/install_extension.ps1`.
- Export extensions: `code --list-extensions > VSCode/extensions`.

## Coding Style & Naming Conventions
- Shell: prefer POSIX sh for portability in `link.sh`; use bash only when needed. New scripts should be executable and start with `#!/bin/sh` or `#!/usr/bin/env bash` and `set -euo pipefail` (for bash).
- Filenames: lowercase with hyphens (e.g., `brew.sh`, `link.sh`). Dotfiles mirror upstream names (e.g., `.zshrc`).
- JSON/YAML: keep stable formatting; use VS Code’s default formatters (Prettier for Markdown/JSON, Shell-Format for shell) as configured in `VSCode/settings.json`.

## Testing Guidelines
- Scripts: dry-run or validate in a new shell session. Example: `zsh -n zsh/.zshrc` for syntax; `shellcheck brew.sh link.sh claude/sync.sh claude/install.sh` if available.
- Claude Code settings: `bash claude/sync.sh` reports drift without writing (exit 3 when there is any), and `bash claude/sync.sh --apply -n` shows what it would persist. Both are safe to run any time. Set `CLAUDE_DIR` to a scratch directory to exercise them without touching `~/.claude`.
- Post-install checks: confirm symlinks exist (e.g., `ls -l ~/.zshrc`), open a new terminal to verify no startup errors, and run `brew bundle --file .Brewfile --no-lock --verbose` without changes.
- No unit test framework is used; keep changes small and manually verifiable.

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:` (matches existing history, e.g., `feat: add zshenv.local`).
- Scope changes narrowly; avoid mixing unrelated edits (zsh, VSCode, Homebrew in separate commits/PRs).
- PRs should include: purpose, affected files, OS tested (macOS, WSL/Windows), and verification steps. Update `README.md` if onboarding changes.

## Security & Configuration Tips
- Never commit secrets. Use `zsh/.zshenv.local` and `zsh/.zshrc.local` (gitignored); copy from `*.example` and edit locally.
- Machine-specific Claude Code settings go in `claude/settings.local.json` (gitignored); copy from `claude/settings.local.json.example`.
- Keep `permissions` and `hooks` in the tracked `claude/settings.json` — never route them to the overlay. `deny-check.sh` fails closed, so a missing deny list is a loud block rather than a silent bypass, but an overlay that *replaces* `permissions` with a weaker list would be a real regression and would only exist on one machine.
- Symlinks overwrite with `ln -sf`; review targets in `link.sh` before running on new machines.
