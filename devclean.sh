#!/bin/bash
set -euo pipefail

# =============================================================
# Developer Maintenance Script
# =============================================================
# Cleans development and AI tool clutter that accumulates over
# time — caches, derived build artifacts, Python bytecode,
# browser storage, package-manager cruft, and oversized logs.
#
# Usage:
#   ./maintain.sh                     → safe mode
#   ./maintain.sh safe               → safe mode
#   ./maintain.sh aggressive         → deeper clean
#   ./maintain.sh deep               → deepest clean
#   ./maintain.sh --dry-run          → preview safe mode only
#   ./maintain.sh deep --dry-run     → preview deep mode
#   ./maintain.sh --dry-run deep     → same as above
#
# Notes:
# - This script avoids touching your real work, credentials,
#   settings, or active environments.
# - "deep" mode is still conservative: it targets caches,
#   logs, and common rebuildable artifacts only.
# - Edit DEV_ROOTS below to match your project directories
#   before running. Only used in "deep" mode.
# =============================================================

# ── Colors ─────────────────────────────────────────────────────
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Defaults ───────────────────────────────────────────────────
MODE="safe"
DRY_RUN=0

# ── Configurable Project Roots ─────────────────────────────────
# Edit these to match where your projects live before running.
# Used by: deep log cleanup (Section 8) and build artifact cleanup (Section 10).
DEV_ROOTS=(
    "$HOME/Projects"
    "$HOME/Developer"
    "$HOME/src"
)

# ── Logging Helpers ────────────────────────────────────────────
log()  { echo -e "${BLUE}➡  ${*}${NC}"; }
ok()   { echo -e "${GREEN}✅ ${*}${NC}"; }
warn() { echo -e "${YELLOW}⚠  ${*}${NC}"; }
err()  { echo -e "${RED}✖  ${*}${NC}"; }

# ── Argument Parsing ───────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        safe|aggressive|deep)
            MODE="$arg"
            ;;
        dry-run|--dry-run|-n)
            DRY_RUN=1
            ;;
        *)
            err "Invalid argument: '$arg'. Use: safe | aggressive | deep [--dry-run]"
            exit 1
            ;;
    esac
done

# ── Header ─────────────────────────────────────────────────────
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
if [ "$DRY_RUN" -eq 1 ]; then
    log "Running Maintenance in [${MODE}] mode... [dry-run]"
else
    log "Running Maintenance in [${MODE}] mode..."
fi
echo -e "${CYAN}══════════════════════════════════════════════${NC}"

# ── Time Machine Guard ─────────────────────────────────────────
if tmutil status 2>/dev/null | grep -q '"Running" = 1'; then
    warn "Time Machine backup is in progress."
    if ! confirm "Continue anyway?"; then
        err "Aborting — run again after backup completes."
        exit 1
    fi
fi

# ── Helpers ────────────────────────────────────────────────────
size_of() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        du -sh "$target" 2>/dev/null | awk '{print $1}'
    fi
}

clean_path() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        local sz
        sz="$(size_of "$target")"
        if [ "$DRY_RUN" -eq 1 ]; then
            log "Dry-run: Would delete → $target${sz:+ ($sz)}"
        else
            rm -rf "$target" || true
            ok "Cleared: $target${sz:+ ($sz)}"
        fi
    fi
}

truncate_file() {
    local target="$1"
    if [ -f "$target" ]; then
        local sz
        sz="$(size_of "$target")"
        if [ "$DRY_RUN" -eq 1 ]; then
            log "Dry-run: Would truncate → $target${sz:+ ($sz)}"
        else
            : > "$target" || true
            ok "Truncated: $target${sz:+ ($sz)}"
        fi
    fi
}

confirm() {
    local prompt="$1"
    printf "${YELLOW}${prompt} (y/N): ${NC}"
    read -r response
    [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
}

run_cmd() {
    local description="$1"
    shift
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would run → $description"
    else
        "$@" 2>/dev/null && ok "$description" || warn "$description encountered issues."
    fi
}

find_delete_dirs() {
    local root="$1"
    local maxdepth="$2"
    shift 2

    [ -d "$root" ] || return 0

    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would search in $root (depth ≤ $maxdepth) for: $*"
        return 0
    fi

    find "$root" -maxdepth "$maxdepth" -type d \( "$@" \) -exec rm -rf {} + 2>/dev/null || true
}

find_delete_files() {
    local root="$1"
    local maxdepth="$2"
    shift 2

    [ -d "$root" ] || return 0

    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would search files in $root (depth ≤ $maxdepth) for: $*"
        return 0
    fi

    find "$root" -maxdepth "$maxdepth" -type f \( "$@" \) -delete 2>/dev/null || true
}

# ════════════════════════════════════════════════════════════════
# SECTION 1 — Claude Code Cache Cleanup
# ════════════════════════════════════════════════════════════════
log "Cleaning Claude Code caches..."
clean_path "$HOME/.cache/claude-cli-nodejs"
clean_path "$HOME/.claude/cache"
clean_path "$HOME/.claude/tmp"
clean_path "$HOME/.claude/logs"
clean_path "$HOME/.claude/statsig"

# ════════════════════════════════════════════════════════════════
# SECTION 2 — Gemini CLI Cache Cleanup
# ════════════════════════════════════════════════════════════════
log "Cleaning Gemini CLI caches..."
clean_path "$HOME/.gemini/tmp"
clean_path "$HOME/.gemini/cache"
clean_path "$HOME/.config/gemini/tmp"
clean_path "$HOME/.config/gemini/cache"

# ════════════════════════════════════════════════════════════════
# SECTION 3 — Codex Cache Cleanup
# ════════════════════════════════════════════════════════════════
log "Cleaning Codex caches..."
clean_path "$HOME/.codex/tmp"
clean_path "$HOME/.codex/cache"
clean_path "$HOME/.config/codex/tmp"
clean_path "$HOME/.config/codex/cache"

# ════════════════════════════════════════════════════════════════
# SECTION 4 — Homebrew
# ════════════════════════════════════════════════════════════════
log "Cleaning Homebrew..."
if command -v brew &>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would run brew cleanup --prune=all"
    else
        brew cleanup --prune=all 2>/dev/null && ok "Homebrew cleaned." || warn "Homebrew cleanup encountered issues."
    fi

    if [[ "$MODE" =~ ^(aggressive|deep)$ ]]; then
        clean_path "$HOME/Library/Caches/Homebrew"
    fi
else
    warn "Homebrew not found, skipping."
fi

# ════════════════════════════════════════════════════════════════
# SECTION 5 — pip / uv / npm
# ════════════════════════════════════════════════════════════════

clean_pip() {
    log "Cleaning pip caches..."
    local found=0

    for pcmd in pip pip3; do
        if command -v "$pcmd" &>/dev/null; then
            found=1
            if [ "$DRY_RUN" -eq 1 ]; then
                local pdir
                pdir="$($pcmd cache dir 2>/dev/null || true)"
                if [ -n "$pdir" ]; then
                    log "Dry-run: Would purge $pcmd cache at $pdir"
                else
                    log "Dry-run: Would run $pcmd cache purge"
                fi
            else
                "$pcmd" cache purge 2>/dev/null && ok "$pcmd cache purged." || warn "$pcmd cache purge encountered issues."
            fi
        fi
    done

    if [ "$found" -eq 0 ]; then
        warn "pip/pip3 not found, skipping."
    fi
}

clean_uv() {
    log "Cleaning uv caches..."
    if command -v uv &>/dev/null; then
        if [ "$DRY_RUN" -eq 1 ]; then
            log "Dry-run: Would run uv cache clean"
            [ -d "$HOME/.cache/uv" ] && log "Dry-run: Would clear fallback cache → $HOME/.cache/uv"
        else
            uv cache clean 2>/dev/null && ok "uv cache cleaned." || {
                warn "uv cache clean encountered issues; trying fallback cache path."
                clean_path "$HOME/.cache/uv"
            }
        fi
    else
        if [ -d "$HOME/.cache/uv" ]; then
            clean_path "$HOME/.cache/uv"
        else
            warn "uv not found, skipping."
        fi
    fi
}

clean_npm() {
    log "Cleaning npm caches..."
    if command -v npm &>/dev/null; then
        if [ "$DRY_RUN" -eq 1 ]; then
            if [ "$MODE" = "safe" ]; then
                log "Dry-run: Would run npm cache verify"
            else
                log "Dry-run: Would run npm cache verify"
                log "Dry-run: Would run npm cache clean --force"
            fi
        else
            npm cache verify 2>/dev/null && ok "npm cache verified." || warn "npm cache verify encountered issues."
            if [[ "$MODE" =~ ^(aggressive|deep)$ ]]; then
                npm cache clean --force 2>/dev/null && ok "npm cache cleaned." || warn "npm cache clean encountered issues."
            fi
        fi
    else
        warn "npm not found, skipping."
    fi
}

clean_pip
clean_uv
clean_npm

# Optional extras if available in deeper modes
if [[ "$MODE" =~ ^(aggressive|deep)$ ]]; then
    log "Cleaning optional JS package manager caches..."

    if command -v pnpm &>/dev/null; then
        if [ "$DRY_RUN" -eq 1 ]; then
            log "Dry-run: Would run pnpm store prune"
        else
            pnpm store prune 2>/dev/null && ok "pnpm store pruned." || warn "pnpm store prune encountered issues."
        fi
    fi

    if command -v yarn &>/dev/null; then
        if [ "$DRY_RUN" -eq 1 ]; then
            log "Dry-run: Would run yarn cache clean"
        else
            yarn cache clean 2>/dev/null && ok "Yarn cache cleaned." || warn "Yarn cache clean encountered issues."
        fi
    fi
fi

# ════════════════════════════════════════════════════════════════
# SECTION 6 — Python / Jupyter Artifacts
# ════════════════════════════════════════════════════════════════
log "Cleaning Python & Jupyter artifacts..."

if [ "$DRY_RUN" -eq 1 ]; then
    if [ "$MODE" = "safe" ]; then
        log "Dry-run: Would find and delete __pycache__ and .ipynb_checkpoints (depth ≤ 4)"
    elif [ "$MODE" = "aggressive" ]; then
        log "Dry-run: Would deeply remove __pycache__, .ipynb_checkpoints, .pytest_cache, .mypy_cache, .ruff_cache (depth ≤ 6)"
    else
        log "Dry-run: Would deeply remove Python/dev caches plus .tox/.nox/.coverage/htmlcov (depth ≤ 7)"
    fi
else
    if [ "$MODE" = "safe" ]; then
        find "$HOME" -maxdepth 4 -type d \
            \( -name "__pycache__" -o -name ".ipynb_checkpoints" \) \
            -exec rm -rf {} + 2>/dev/null || true
        ok "Python/Jupyter artifacts purged (shallow pass)."

    elif [ "$MODE" = "aggressive" ]; then
        find "$HOME" -maxdepth 6 -type d \
            \( -name "__pycache__" -o \
               -name ".ipynb_checkpoints" -o \
               -name ".pytest_cache" -o \
               -name ".mypy_cache" -o \
               -name ".ruff_cache" \) \
            -exec rm -rf {} + 2>/dev/null || true
        find "$HOME" -maxdepth 6 -type f \
            \( -name ".coverage" \) \
            -delete 2>/dev/null || true
        ok "Python/Jupyter artifacts purged."

    else
        find "$HOME" -maxdepth 7 -type d \
            \( -name "__pycache__" -o \
               -name ".ipynb_checkpoints" -o \
               -name ".pytest_cache" -o \
               -name ".mypy_cache" -o \
               -name ".ruff_cache" -o \
               -name ".tox" -o \
               -name ".nox" -o \
               -name "htmlcov" \) \
            -exec rm -rf {} + 2>/dev/null || true
        find "$HOME" -maxdepth 7 -type f \
            \( -name ".coverage" \) \
            -delete 2>/dev/null || true
        ok "Python/Jupyter artifacts purged (deep pass)."
    fi
fi

# ════════════════════════════════════════════════════════════════
# SECTION 7 — Xcode & Developer Caches
# ════════════════════════════════════════════════════════════════
log "Cleaning Xcode & developer caches..."
clean_path "$HOME/Library/Developer/Xcode/DerivedData"
clean_path "$HOME/Library/Caches/com.apple.dt.Xcode"

if [[ "$MODE" =~ ^(aggressive|deep)$ ]]; then
    clean_path "$HOME/Library/Developer/Xcode/Archives"
    clean_path "$HOME/Library/Developer/CoreSimulator/Caches"
fi

# ════════════════════════════════════════════════════════════════
# SECTION 8 — Logs
# ════════════════════════════════════════════════════════════════
log "Cleaning logs..."

clean_large_logs_in_dir() {
    local dir="$1"
    local size_threshold="${2:-50M}"

    [ -d "$dir" ] || return 0

    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would inspect large logs in $dir (>${size_threshold})"
        find "$dir" -type f \( -name "*.log" -o -name "*.txt" \) -size +"$size_threshold" -print 2>/dev/null || true
        return 0
    fi

    while IFS= read -r file; do
        truncate_file "$file"
    done < <(find "$dir" -type f \( -name "*.log" -o -name "*.txt" \) -size +"$size_threshold" -print 2>/dev/null || true)
}

# Safe mode: only obvious user-space logs
clean_large_logs_in_dir "$HOME/Library/Logs" "50M"
clean_large_logs_in_dir "$HOME/.claude/logs" "20M"
clean_large_logs_in_dir "$HOME/.gemini/logs" "20M"
clean_large_logs_in_dir "$HOME/.codex/logs" "20M"

if [[ "$MODE" =~ ^(aggressive|deep)$ ]]; then
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would delete rotated/compressed logs older than 14 days from ~/Library/Logs"
    else
        find "$HOME/Library/Logs" -type f \
            \( -name "*.0" -o -name "*.1" -o -name "*.old" -o -name "*.gz" \) \
            -mtime +14 -delete 2>/dev/null || true
        ok "Old rotated logs cleaned."
    fi
fi

if [ "$MODE" = "deep" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would remove stray *.log files older than 30 days from dev roots"
    else
        for root in "${DEV_ROOTS[@]}" "$HOME/Documents" "$HOME/Downloads"; do
            [ -d "$root" ] || continue
            find "$root" -maxdepth 5 -type f -name "*.log" -mtime +30 -size +5M -delete 2>/dev/null || true
        done
        ok "Deep log cleanup complete."
    fi
fi

# ════════════════════════════════════════════════════════════════
# SECTION 9 — Chrome (Aggressive/Deep Only, with confirmation)
# ════════════════════════════════════════════════════════════════
if [[ "$MODE" =~ ^(aggressive|deep)$ ]]; then
    warn "${MODE^} mode: Chrome web storage will be cleared."
    warn "This removes offline app data (IndexedDB, Service Workers)."
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would prompt to clear Chrome web storage."
    else
        if confirm "Clear Chrome web storage?"; then
            clean_path "$HOME/Library/Application Support/Google/Chrome/Default/IndexedDB"
            clean_path "$HOME/Library/Application Support/Google/Chrome/Default/Service Worker"
            clean_path "$HOME/Library/Application Support/Google/Chrome/Default/Cache"
        else
            warn "Chrome cleanup skipped."
        fi
    fi
fi

# ════════════════════════════════════════════════════════════════
# SECTION 10 — Deep Project Artifact Cleanup
# ════════════════════════════════════════════════════════════════
if [ "$MODE" = "deep" ]; then
    log "Cleaning project build caches..."

    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run: Would remove rebuildable project artifacts (.next, .turbo, .vite, dist, build, target)"
    else
        for root in "${DEV_ROOTS[@]}"; do
            [ -d "$root" ] || continue
            find "$root" -maxdepth 5 -type d \
                \( -name ".next" -o \
                   -name ".turbo" -o \
                   -name ".vite" -o \
                   -name "dist" -o \
                   -name "build" -o \
                   -name "target" \) \
                -exec rm -rf {} + 2>/dev/null || true
        done
        ok "Project build caches purged."
    fi
fi

# ════════════════════════════════════════════════════════════════
# SECTION 11 — Trash
# ════════════════════════════════════════════════════════════════
log "Finalizing..."
if [ "$DRY_RUN" -eq 0 ]; then
    if confirm "Empty Trash?"; then
        if [ -n "$(ls -A "$HOME/.Trash/" 2>/dev/null)" ]; then
            rm -rf "$HOME/.Trash/"* || true
            ok "Trash emptied."
        else
            warn "Trash was already empty."
        fi
    else
        warn "Trash not emptied."
    fi
else
    log "Dry-run: Would prompt to empty Trash."
fi

# ════════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════════
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
if [ "$DRY_RUN" -eq 1 ]; then
    ok "Cleanup preview complete! [mode: ${MODE}, dry-run]"
else
    ok "Cleanup complete! [mode: ${MODE}]"
fi
echo ""
df -h / | awk 'NR==1 || /\/$/ {print}'
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
