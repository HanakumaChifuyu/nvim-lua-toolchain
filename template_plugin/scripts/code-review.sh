#!/bin/bash
# code-review.sh - AI-powered code review using Claude Code headless mode
# Integrates with pre-push hook to automatically review changes before push
#
# Exit codes:
#   0 - No issues found
#   1 - Review failed (error running review)
#   2 - Critical issues found (confidence >= 80)

set -e

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_header() { echo -e "\n${CYAN}${BOLD}$1${NC}\n"; }

# Check if claude CLI is available
check_claude_cli() {
    if ! command -v claude &> /dev/null; then
        log_error "Claude CLI not found. Please install Claude Code first."
        log_info "Visit: https://docs.anthropic.com/en/docs/claude-code"
        exit 1
    fi
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        log_error "Not a git repository. Cannot perform code review."
        exit 1
    fi
}

# Determine what to review
get_review_target() {
    local staged_lines=$(git diff --cached --stat 2>/dev/null | wc -l)
    local has_staged=$((staged_lines > 1))

    if [ "$has_staged" -eq 1 ]; then
        echo "staged"
        return 0
    fi

    # Check if there are unpushed commits
    local unpushed=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l)
    if [ "$unpushed" -gt 0 ]; then
        echo "unpushed"
        return 0
    fi

    echo "last-commit"
}

# Get the diff content for review
get_diff_content() {
    local target="$1"
    local max_lines=500

    case "$target" in
        "staged")
            log_info "Reviewing staged changes..."
            git diff --cached --stat
            echo "---"
            git diff --cached | head -n $max_lines
            ;;
        "unpushed")
            log_info "Reviewing unpushed commits..."
            git log @{u}..HEAD --oneline
            echo "---"
            git diff @{u}..HEAD | head -n $max_lines
            ;;
        "last-commit"|*)
            log_info "Reviewing last commit..."
            git log -1 --oneline
            echo "---"
            git show HEAD --stat
            echo "---"
            git show HEAD --format="" | head -n $max_lines
            ;;
    esac
}

# Run code review using Claude
run_code_review() {
    local target="$1"
    local diff_content
    local prompt_file

    # Get diff content
    diff_content=$(get_diff_content "$target")

    if [ -z "$diff_content" ] || [ "$diff_content" = "---" ]; then
        log_warn "No changes to review."
        exit 0
    fi

    # Check if we have the code-review command file
    local skill_dir
    skill_dir="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
    prompt_file="$skill_dir/commands/code-review.md"

    # Build the review prompt
    local review_prompt
    if [ -f "$prompt_file" ]; then
        # Use the skill's code-review.md as context
        review_prompt=$(cat <<'PROMPT_EOF'
Review the following git diff for issues. Focus on:
1. Security vulnerabilities (arbitrary code execution, unsafe vim commands)
2. Logic bugs and edge cases
3. Lua / Neovim plugin best practices
4. Performance issues (blocking main thread, unnecessary re-renders)

For each issue, provide:
- Confidence score (0-100)
- File and line number
- Description and suggested fix

Only report issues with confidence >= 70.

Format your response as:
## Code Review

### Critical (Confidence 80+)
- [issue description]
  - File: path/to/file.lua:line
  - Fix: [suggested fix]

### Warnings (Confidence 70-79)
- [issue description]
  - File: path/to/file.lua:line
  - Suggestion: [improvement]

### Passed Checks
- Security: [summary]
- Bugs: [summary]
- Best Practices: [summary]
- Performance: [summary]

If no issues found with confidence >= 70, just report the Passed Checks section.

---
Changes to review:
PROMPT_EOF
)
    else
        review_prompt="Review these code changes for security, bugs, best practices, and performance issues. Report only issues with high confidence (>= 70)."
    fi

    # Run Claude in print mode (headless)
    log_info "Running AI code review with Claude..."

    local output
    local exit_code=0

    # Use --print for headless mode, --allowedTools for git commands
    output=$(echo "$review_prompt

$diff_content" | claude --print 2>&1) || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Code review failed to run."
        echo "$output"
        exit 1
    fi

    # Output the review results
    echo "$output"

    # Check for critical issues in output
    if echo "$output" | grep -qiE "critical|confidence (8[0-9]|9[0-9]|100)"; then
        return 2
    fi

    return 0
}

# Main
main() {
    log_header "🔍 AI Code Review"

    check_claude_cli
    check_git_repo

    local target
    target=$(get_review_target)

    log_info "Review target: $target"

    # Run the review
    run_code_review "$target"
    local result=$?

    echo ""

    case $result in
        0)
            log_success "Code review passed - no critical issues found!"
            ;;
        2)
            log_warn "Critical issues found! Please review the output above."
            ;;
        *)
            log_error "Code review encountered an error."
            ;;
    esac

    exit $result
}

main "$@"
