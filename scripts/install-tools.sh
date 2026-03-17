#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$ROOT_DIR/tests"
PLENARY_DIR="$ROOT_DIR/vendor/plenary.nvim"
ROCKS_TREE="$TESTS_DIR/.rocks"
LUA_VERSION="5.1"

usage() {
  cat <<'EOF'
Usage: ./scripts/install-tools.sh [install|check]

install  Verify prerequisites, clone plenary.nvim into vendor/,
         and install luacov into tests/.rocks/.
check    Verify prerequisites and print the local paths that will be used.
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

check_prerequisites() {
  require_cmd nvim
  require_cmd git
  require_cmd just
  require_cmd luarocks
}

install_plenary() {
  mkdir -p "$ROOT_DIR/vendor"

  if [ -d "$PLENARY_DIR/.git" ]; then
    printf 'plenary.nvim already present at %s\n' "$PLENARY_DIR"
    return 0
  fi

  if [ -e "$PLENARY_DIR" ]; then
    printf 'Refusing to overwrite non-git path: %s\n' "$PLENARY_DIR" >&2
    exit 1
  fi

  git clone --depth=1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_DIR"
}

install_luacov() {
  mkdir -p "$ROCKS_TREE"

  if luarocks --tree "$ROCKS_TREE" --lua-version="$LUA_VERSION" show luacov >/dev/null 2>&1; then
    printf 'luacov already installed in %s\n' "$ROCKS_TREE"
    return 0
  fi

  luarocks --tree "$ROCKS_TREE" --lua-version="$LUA_VERSION" install luacov
}

print_summary() {
  cat <<EOF
Installed sample test dependencies.

Next steps:
  cd "$ROOT_DIR" && just test
  cd "$ROOT_DIR" && just test tests/tools_spec.lua
  cd "$ROOT_DIR" && tests/.rocks/bin/luacov
EOF
}

main() {
  local mode="${1:-install}"

  case "$mode" in
    install)
      check_prerequisites
      install_plenary
      install_luacov
      print_summary
      ;;
    check)
      check_prerequisites
      printf 'Will use plenary at %s\n' "$PLENARY_DIR"
      printf 'Will use LuaRocks tree at %s\n' "$ROCKS_TREE"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
