#!/usr/bin/env bash
# ==============================================================================
#  OpenCode Terminal Chat (v1.0 - Terminal Interface)
#  Description: Terminal interface for opencode with chat loop and proper cleanup.
# ==============================================================================

# --- 1. Strict Mode ---
set -euo pipefail

# --- 2. Configuration ---
readonly CONFIG_DIR="${HOME}/.config/opencode-terminal"
readonly STATE_FILE="${CONFIG_DIR}/last_session"
readonly MAX_CLIPBOARD_LEN=4000

# --- 3. Formatting (ANSI) ---
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly YELLOW=$'\033[0;33m'
readonly CYAN=$'\033[0;36m'
readonly RESET=$'\033[0m'

# --- 4. Runtime State ---
HISTORY_FILE=""

# --- 5. Cleanup (Trap-Safe) ---
cleanup() {
	[[ -n "${HISTORY_FILE:-}" && -f "$HISTORY_FILE" ]] && rm -f "$HISTORY_FILE"
	# Restore cursor visibility
	printf '\033[?25h' 2>/dev/null || true
}
trap cleanup EXIT INT TERM HUP

# --- 6. Core Utility Functions ---
log_info() { printf '%b[INFO]%b %s\n' "$BLUE" "$RESET" "$1"; }
log_warn() { printf '%b[WARN]%b %s\n' "$YELLOW" "$RESET" "$1" >&2; }
log_err() { printf '%b[ERROR]%b %s\n' "$RED" "$RESET" "$1" >&2; }

die() {
	log_err "$1"
	exit "${2:-1}"
}

# --- 7. Dependency Checks ---
check_dependencies() {
	local -a missing=()
	local cmd

	# Check for opencode
	if ! command -v opencode &>/dev/null; then
		log_warn "opencode command not found in PATH"
		log_warn "Please ensure opencode is installed and accessible"
		die "opencode not found"
	fi
}

# --- 8. Session Management ---
save_state() {
	printf '%s\n' "$1" >"$STATE_FILE"
}

# --- 9. Conversation History ---
update_history() {
	local role="$1"
	local content="$2"

	# Skip effectively empty content
	[[ -z "${content//[[:space:]]/}" ]] && return 0

	local temp_file
	temp_file=$(mktemp) || {
		log_warn "mktemp failed in update_history"
		return 1
	}

	printf '[%s] %s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$role" "$content" >>"$temp_file"

	if [[ -f "$HISTORY_FILE" ]]; then
		cat "$HISTORY_FILE" >>"$temp_file"
	fi

	mv -f "$temp_file" "$HISTORY_FILE"
}

# --- 10. UI ---
print_header() {
	clear
	printf '%b========================================%b\n' "$CYAN" "$RESET"
	printf ' %bOpenCode Terminal Chat%b %b(v1.0)%b\n' "$BOLD" "$RESET" "$DIM" "$RESET"
	printf ' %bCommands:%b /clear, /exit, /help\n' "$DIM" "$RESET"
	printf '%b========================================%b\n\n' "$CYAN" "$RESET"
}

print_help() {
	printf '%bAvailable Commands:%b\n' "$BOLD" "$RESET"
	printf '  /clear   - Clear conversation history\n'
	printf '  /exit    - Exit the chat (or Ctrl+D)\n'
	printf '  /help    - Show this message\n\n'
}

# ==============================================================================
# --- MAIN EXECUTION ---
# ==============================================================================

# Pre-flight checks
check_dependencies
[[ -d "$CONFIG_DIR" ]] || mkdir -p "$CONFIG_DIR"

# Initialize temp file (registered for cleanup via trap)
HISTORY_FILE=$(mktemp --tmpdir opencode_hist.XXXXXX.txt)

print_header

# ==============================================================================
# --- MAIN CHAT LOOP ---
# ==============================================================================
while true; do
	user_input=""

	# 1. Acquire user input
	printf '%bYou:%b ' "$BOLD" "$RESET"
	if ! IFS= read -e -r user_input; then
		# EOF (Ctrl+D)
		printf '\n'
		break
	fi

	# 2. Handle slash commands
	case "$user_input" in
	/exit | /quit | /q)
		break
		;;
	/clear)
		printf '' >"$HISTORY_FILE"
		print_header
		continue
		;;
	/help | /h | \?)
		print_help
		continue
		;;
	"")
		continue
		;;
	esac

	# 3. Append user message to history
	update_history "user" "$user_input"

	# 4. Send to opencode and display response
	printf '\n%b%bOpenCode:%b ' "$CYAN" "$BOLD" "$RESET"

	# Execute opencode with user input
	if response=$(opencode "$user_input" 2>&1); then
		printf '%s\n' "$response"
		update_history "opencode" "$response"
	else
		printf '%b[Error: OpenCode execution failed]%b\n' "$RED" "$RESET"
		update_history "error" "OpenCode execution failed"
	fi

	printf '\n'
done

printf '%b👋 Goodbye!%b\n' "$DIM" "$RESET"
exit 0
