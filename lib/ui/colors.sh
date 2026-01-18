#!/bin/bash
# OmniSet v2 - Color Definitions
# lib/ui/colors.sh

# Detect terminal capabilities
_detect_color_support() {
    # Check if stdout is a terminal
    if [[ ! -t 1 ]]; then
        return 1
    fi

    # Check TERM
    case "$TERM" in
        xterm*|rxvt*|vte*|screen*|tmux*|linux|cygwin)
            return 0
            ;;
        dumb)
            return 1
            ;;
    esac

    # Check for color support
    if command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null) -ge 8 ]]; then
        return 0
    fi

    return 1
}

# Detect Unicode support
_detect_unicode_support() {
    if [[ "$LANG" =~ UTF-8 ]] || [[ "$LC_ALL" =~ UTF-8 ]] || [[ "$LC_CTYPE" =~ UTF-8 ]]; then
        return 0
    fi
    return 1
}

# Initialize colors
init_colors() {
    if _detect_color_support; then
        # Standard colors
        export BLACK='\033[0;30m'
        export RED='\033[0;31m'
        export GREEN='\033[0;32m'
        export YELLOW='\033[0;33m'
        export BLUE='\033[0;34m'
        export PURPLE='\033[0;35m'
        export CYAN='\033[0;36m'
        export WHITE='\033[0;37m'

        # Bright colors
        export BRIGHT_BLACK='\033[1;30m'
        export BRIGHT_RED='\033[1;31m'
        export BRIGHT_GREEN='\033[1;32m'
        export BRIGHT_YELLOW='\033[1;33m'
        export BRIGHT_BLUE='\033[1;34m'
        export BRIGHT_PURPLE='\033[1;35m'
        export BRIGHT_CYAN='\033[1;36m'
        export BRIGHT_WHITE='\033[1;37m'

        # Background colors
        export BG_RED='\033[41m'
        export BG_GREEN='\033[42m'
        export BG_YELLOW='\033[43m'
        export BG_BLUE='\033[44m'

        # Formatting
        export BOLD='\033[1m'
        export DIM='\033[2m'
        export ITALIC='\033[3m'
        export UNDERLINE='\033[4m'
        export BLINK='\033[5m'
        export REVERSE='\033[7m'
        export HIDDEN='\033[8m'
        export STRIKETHROUGH='\033[9m'

        # Reset
        export NC='\033[0m'
        export RESET='\033[0m'

        export HAS_COLORS=true
    else
        # No colors - set empty strings
        export BLACK='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
        export BRIGHT_BLACK='' BRIGHT_RED='' BRIGHT_GREEN='' BRIGHT_YELLOW=''
        export BRIGHT_BLUE='' BRIGHT_PURPLE='' BRIGHT_CYAN='' BRIGHT_WHITE=''
        export BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE=''
        export BOLD='' DIM='' ITALIC='' UNDERLINE='' BLINK='' REVERSE='' HIDDEN='' STRIKETHROUGH=''
        export NC='' RESET=''

        export HAS_COLORS=false
    fi
}

# Initialize symbols
init_symbols() {
    if _detect_unicode_support; then
        export SYM_CHECK="✓"
        export SYM_CROSS="✗"
        export SYM_WARNING="⚠"
        export SYM_INFO="ℹ"
        export SYM_ARROW="→"
        export SYM_BULLET="•"
        export SYM_STAR="★"
        export SYM_CIRCLE="●"
        export SYM_SQUARE="■"
        export SYM_DIAMOND="◆"

        # Progress bar characters
        export SYM_PROG_FULL="█"
        export SYM_PROG_EMPTY="░"
        export SYM_PROG_HALF="▓"

        # Spinner frames
        export -a SYM_SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

        # Box drawing
        export SYM_BOX_TL="╭"
        export SYM_BOX_TR="╮"
        export SYM_BOX_BL="╰"
        export SYM_BOX_BR="╯"
        export SYM_BOX_H="─"
        export SYM_BOX_V="│"

        export HAS_UNICODE=true
    else
        export SYM_CHECK="+"
        export SYM_CROSS="x"
        export SYM_WARNING="!"
        export SYM_INFO="i"
        export SYM_ARROW=">"
        export SYM_BULLET="*"
        export SYM_STAR="*"
        export SYM_CIRCLE="o"
        export SYM_SQUARE="#"
        export SYM_DIAMOND="+"

        export SYM_PROG_FULL="="
        export SYM_PROG_EMPTY="-"
        export SYM_PROG_HALF="+"

        export -a SYM_SPINNER=("|" "/" "-" "\\")

        export SYM_BOX_TL="+"
        export SYM_BOX_TR="+"
        export SYM_BOX_BL="+"
        export SYM_BOX_BR="+"
        export SYM_BOX_H="-"
        export SYM_BOX_V="|"

        export HAS_UNICODE=false
    fi
}

# Get terminal dimensions
get_terminal_size() {
    if command -v tput &>/dev/null; then
        TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
        TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
    else
        TERM_WIDTH=80
        TERM_HEIGHT=24
    fi
    export TERM_WIDTH TERM_HEIGHT
}

# Initialize all UI settings
init_ui() {
    init_colors
    init_symbols
    get_terminal_size
}
