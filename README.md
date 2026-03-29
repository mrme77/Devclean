# Devclean

A macOS maintenance script that cleans dev caches, build artifacts, and AI tool clutter.

Devclean targets the stuff that quietly eats your disk — `__pycache__`, `DerivedData`, `node_modules` caches, Homebrew leftovers, Claude/Gemini/Codex temp files, oversized logs, and more. It stays away from your actual work, credentials, and settings.

## Quick Start
```bash
git clone https://github.com/YOUR_USERNAME/devclean.git
cd devclean
chmod +x devclean.sh
./devclean.sh
```

## Usage
```bash
./devclean.sh              # safe mode (default)
./devclean.sh aggressive   # deeper clean
./devclean.sh deep         # deepest clean
./devclean.sh --dry-run    # preview what would be deleted
./devclean.sh deep --dry-run
```

## Modes

**Safe** — the default. Clears obvious caches and temp files: AI CLI caches (Claude, Gemini, Codex), Homebrew cleanup, pip/uv/npm cache verification, shallow `__pycache__` and `.ipynb_checkpoints` removal, Xcode `DerivedData`, and large log truncation.

**Aggressive** — everything in safe, plus: Homebrew download cache, forced npm cache clean, pnpm/yarn cache purge, deeper Python artifact removal (`.pytest_cache`, `.mypy_cache`, `.ruff_cache`), old rotated logs, and Chrome web storage (with confirmation).

**Deep** — everything in aggressive, plus: `.tox`, `.nox`, `htmlcov` removal, stale `.log` files in project directories, and rebuildable build artifacts (`.next`, `.turbo`, `.vite`, `dist`, `build`, `target`).

## Configuration

Edit the `DEV_ROOTS` array near the top of the script to match where your projects live:
```bash
DEV_ROOTS=(
    "$HOME/Projects"
    "$HOME/Developer"
    "$HOME/src"
)
```

## What It Cleans

| Category | Examples |
|---|---|
| AI tool caches | `.claude/cache`, `.gemini/tmp`, `.codex/cache` |
| Package managers | pip, uv, npm, pnpm, yarn, Homebrew |
| Python artifacts | `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.coverage` |
| Xcode | `DerivedData`, simulator caches, archives |
| Build artifacts | `.next`, `.turbo`, `.vite`, `dist`, `build`, `target` |
| Logs | Large logs truncated, old rotated logs removed |
| Browser | Chrome IndexedDB, Service Workers, cache (with confirmation) |

## What It Won't Touch

Source code, git repositories, configuration files, credentials/keys, active virtual environments, or anything outside the targeted cache/artifact patterns.

## Roadmap

- [ ] TOML/YAML config file for user-defined rules
- [ ] Linux support
- [ ] Python rewrite with `pipx install devclean`
- [ ] Plugin system for custom cleanup modules

## License

MIT
