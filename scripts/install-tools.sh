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
    copy_template_file ".luacov" ".luacov"
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

  # Run a single spec
  cd "$TARGET_DIR" && just test tests/your_spec.lua

  # Run tests + coverage report
  cd "$TARGET_DIR" && just coverage
EOF
}

# ── main ───────────────────────────────────────────────────────────────────────
main() {
    local mode="${1:-install}"

    case "$mode" in
    install)
        check_prerequisites
        apply_templates
        install_luacov
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
