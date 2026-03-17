#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../template_plugin"
TARGET_DIR="$(pwd)"
TESTS_DIR="$TARGET_DIR/tests"
ROCKS_TREE="$TESTS_DIR/.rocks"
LUA_VERSION="5.1"

# ── helpers ────────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: $(basename "$0") [install|check]

  install  (default) Copy template files into the current directory and
           install luacov into tests/.rocks/.
  check    Verify prerequisites and show what would be done.

The script is meant to be run from the root of your Neovim plugin repo:
  cd ~/my-plugin && path/to/nvim-lua-toolchain/scripts/install-tools.sh
EOF
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'ERROR: required command not found: %s\n' "$1" >&2
        exit 1
    fi
}

check_prerequisites() {
    require_cmd nvim
    require_cmd git
    require_cmd just
    require_cmd luarocks
}

# ── template application ───────────────────────────────────────────────────────
copy_template_file() {
    local src="$1" # relative to TEMPLATE_DIR
    local dst="$2" # relative to TARGET_DIR

    local full_src="$TEMPLATE_DIR/$src"
    local full_dst="$TARGET_DIR/$dst"

    if [ ! -f "$full_src" ]; then
        printf 'ERROR: template file not found: %s\n' "$full_src" >&2
        exit 1
    fi

    if [ -f "$full_dst" ]; then
        printf 'SKIP  %s  (already exists)\n' "$dst"
        return 0
    fi

    mkdir -p "$(dirname "$full_dst")"
    cp "$full_src" "$full_dst"
    printf 'COPY  %s\n' "$dst"
}

apply_templates() {
    copy_template_file "tests/minimal_init.lua" "tests/minimal_init.lua"
    copy_template_file ".luacov"                ".luacov"
    copy_template_file ".luacheckrc"            ".luacheckrc"
    copy_template_file "lefthook.yml"           "lefthook.yml"
    copy_template_file "justfile"               "justfile"
    copy_template_file "stylua.toml"            "stylua.toml"
}

# ── stylua ─────────────────────────────────────────────────────────────────────
install_stylua() {
    if command -v stylua >/dev/null 2>&1; then
        printf 'SKIP  stylua already installed (%s)\n' "$(stylua --version 2>&1)"
        return 0
    fi

    # Prefer cargo if available
    if command -v cargo >/dev/null 2>&1; then
        printf 'Installing stylua via cargo ...\n'
        cargo install stylua
        return 0
    fi

    # Fall back to downloading the binary from GitHub releases
    local version
    version="$(curl -fsSL https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest \
        | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')"

    if [ -z "$version" ]; then
        printf 'WARN  could not fetch latest stylua version — install manually:\n'
        printf '      https://github.com/JohnnyMorganz/StyLua/releases\n'
        return 0
    fi

    local arch os asset
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *)
            printf 'WARN  unsupported arch %s — install stylua manually\n' "$arch"
            return 0
            ;;
    esac
    case "$os" in
        linux)  asset="stylua-linux-${arch}.zip" ;;
        darwin) asset="stylua-macos-${arch}.zip" ;;
        *)
            printf 'WARN  unsupported OS %s — install stylua manually\n' "$os"
            return 0
            ;;
    esac

    local url="https://github.com/JohnnyMorganz/StyLua/releases/download/v${version}/${asset}"
    local tmp
    tmp="$(mktemp -d)"
    printf 'Downloading stylua v%s ...\n' "$version"
    curl -fsSL "$url" -o "$tmp/stylua.zip"
    unzip -q "$tmp/stylua.zip" -d "$tmp"
    install -m 755 "$tmp/stylua" "$HOME/.local/bin/stylua"
    rm -rf "$tmp"
    printf 'Installed stylua to ~/.local/bin/stylua\n'
    printf 'Ensure ~/.local/bin is in your PATH.\n'
}

# ── luacheck ──────────────────────────────────────────────────────────────────
check_luacheck() {
    if command -v luacheck >/dev/null 2>&1; then
        printf 'SKIP  luacheck already installed (%s)\n' "$(luacheck --version 2>&1 | head -1)"
        return 0
    fi

    printf 'WARN  luacheck not found — install with one of:\n'
    printf '      luarocks install luacheck\n'
    printf '      apt install lua-check  (Debian/Ubuntu)\n'
}

# ── lefthook ───────────────────────────────────────────────────────────────────
install_lefthook_hooks() {
    if ! command -v lefthook >/dev/null 2>&1; then
        printf 'SKIP  lefthook not found — skipping hook installation\n'
        printf '      Install: https://github.com/evilmartians/lefthook#installation\n'
        return 0
    fi

    if [ ! -d "$TARGET_DIR/.git" ]; then
        printf 'SKIP  no .git directory in %s — skipping lefthook install\n' "$TARGET_DIR"
        return 0
    fi

    printf 'Running lefthook install ...\n'
    (cd "$TARGET_DIR" && lefthook install)
}

# ── luacov ─────────────────────────────────────────────────────────────────────
install_luacov() {
    mkdir -p "$ROCKS_TREE"

    if luarocks --tree "$ROCKS_TREE" --lua-version="$LUA_VERSION" show luacov >/dev/null 2>&1; then
        printf 'SKIP  luacov already installed in %s\n' "$ROCKS_TREE"
        return 0
    fi

    printf 'Installing luacov into %s ...\n' "$ROCKS_TREE"
    luarocks --tree "$ROCKS_TREE" --lua-version="$LUA_VERSION" install luacov
}

print_summary() {
    cat <<EOF

Done. Next steps:

  # Run all tests
  cd "$TARGET_DIR" && just test

  # Run tests + coverage report
  cd "$TARGET_DIR" && just coverage

  # Check coverage against threshold (default 80%, edit justfile min_coverage to change)
  cd "$TARGET_DIR" && just check-coverage

  # Format Lua files
  cd "$TARGET_DIR" && just fmt

  # Git hooks (pre-commit: fmt + coverage check) — requires lefthook
  cd "$TARGET_DIR" && lefthook install
EOF
}

# ── main ───────────────────────────────────────────────────────────────────────
main() {
    local mode="${1:-install}"

    case "$mode" in
    install)
        check_prerequisites
        apply_templates
        install_stylua
        check_luacheck
        install_luacov
        install_lefthook_hooks
        print_summary
        ;;
    check)
        check_prerequisites
        printf 'Template dir : %s\n' "$TEMPLATE_DIR"
        printf 'Target dir   : %s\n' "$TARGET_DIR"
        printf 'LuaRocks tree: %s\n' "$ROCKS_TREE"
        printf 'All prerequisites satisfied.\n'
        ;;
    -h | --help | help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
    esac
}

main "$@"
