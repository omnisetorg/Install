#!/bin/bash
# OmniSet v2 - Print Functions
# lib/ui/print.sh

# Ensure colors are initialized
[[ -z "$NC" ]] && source "${OMNISET_LIB}/ui/colors.sh" && init_ui

# ═══════════════════════════════════════════════════════════════
# Basic Print Functions
# ═══════════════════════════════════════════════════════════════

# Print to stdout
print() {
    echo -e "$*"
}

# Print without newline
printn() {
    echo -en "$*"
}

# Print to stderr
printerr() {
    echo -e "$*" >&2
}

# ═══════════════════════════════════════════════════════════════
# Semantic Print Functions
# ═══════════════════════════════════════════════════════════════

print_success() {
    local message="$1"
    print "${GREEN}${SYM_CHECK}${NC} ${message}"
}

print_error() {
    local message="$1"
    printerr "${RED}${SYM_CROSS}${NC} ${BRIGHT_RED}${message}${NC}"
}

print_warning() {
    local message="$1"
    print "${YELLOW}${SYM_WARNING}${NC} ${BRIGHT_YELLOW}${message}${NC}"
}

print_info() {
    local message="$1"
    print "${CYAN}${SYM_INFO}${NC} ${message}"
}

print_step() {
    local message="$1"
    local step_num="${2:-}"
    local total="${3:-}"

    if [[ -n "$step_num" && -n "$total" ]]; then
        print "${BLUE}${SYM_ARROW}${NC} ${BOLD}[${step_num}/${total}]${NC} ${message}"
    else
        print "${BLUE}${SYM_ARROW}${NC} ${message}"
    fi
}

print_bullet() {
    local message="$1"
    local indent="${2:-2}"
    printf "%*s${DIM}${SYM_BULLET}${NC} %s\n" "$indent" "" "$message"
}

print_debug() {
    if [[ "${OMNISET_DEBUG:-false}" == "true" ]]; then
        print "${DIM}[DEBUG] $1${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Formatted Print Functions
# ═══════════════════════════════════════════════════════════════

# Print a header box
print_header() {
    local message="$1"
    local width=$((TERM_WIDTH - 4))
    local padding=$(( (width - ${#message} - 2) ))

    print ""
    print "${BOLD}${BLUE}${SYM_BOX_TL}$(printf "${SYM_BOX_H}%.0s" $(seq 1 $width))${SYM_BOX_TR}${NC}"
    printf "${BOLD}${BLUE}${SYM_BOX_V}${NC} %-*s ${BOLD}${BLUE}${SYM_BOX_V}${NC}\n" $((width-2)) "$message"
    print "${BOLD}${BLUE}${SYM_BOX_BL}$(printf "${SYM_BOX_H}%.0s" $(seq 1 $width))${SYM_BOX_BR}${NC}"
    print ""
}

# Print a section divider
print_divider() {
    local char="${1:-$SYM_BOX_H}"
    local width=$((TERM_WIDTH - 4))
    print "${DIM}$(printf "${char}%.0s" $(seq 1 $width))${NC}"
}

# Print a key-value pair
print_kv() {
    local key="$1"
    local value="$2"
    local key_width="${3:-20}"
    printf "  ${BOLD}%-*s${NC} %s\n" "$key_width" "${key}:" "$value"
}

# Print a list item with status
print_status() {
    local item="$1"
    local status="$2"
    local width=$((TERM_WIDTH - 20))

    case "$status" in
        ok|success|installed)
            printf "  %-*s ${GREEN}[${SYM_CHECK} OK]${NC}\n" "$width" "$item"
            ;;
        fail|failed|error)
            printf "  %-*s ${RED}[${SYM_CROSS} FAIL]${NC}\n" "$width" "$item"
            ;;
        skip|skipped)
            printf "  %-*s ${YELLOW}[- SKIP]${NC}\n" "$width" "$item"
            ;;
        pending)
            printf "  %-*s ${DIM}[...]${NC}\n" "$width" "$item"
            ;;
        *)
            printf "  %-*s [%s]\n" "$width" "$item" "$status"
            ;;
    esac
}

# Print in columns
print_columns() {
    local -a items=("$@")
    local cols=3
    local col_width=$((TERM_WIDTH / cols - 2))
    local count=0

    for item in "${items[@]}"; do
        printf "  %-*s" "$col_width" "$item"
        count=$((count + 1))
        if (( count % cols == 0 )); then
            print ""
        fi
    done

    if (( count % cols != 0 )); then
        print ""
    fi
}

# ═══════════════════════════════════════════════════════════════
# Banner and Branding
# ═══════════════════════════════════════════════════════════════

print_banner() {
    local show_version="${1:-true}"

    print ""
    print "${BRIGHT_GREEN}"
    print "   ██████╗ ███╗   ███╗███╗   ██╗██╗███████╗███████╗████████╗"
    print "  ██╔═══██╗████╗ ████║████╗  ██║██║██╔════╝██╔════╝╚══██╔══╝"
    print "  ██║   ██║██╔████╔██║██╔██╗ ██║██║███████╗█████╗     ██║   "
    print "  ██║   ██║██║╚██╔╝██║██║╚██╗██║██║╚════██║██╔══╝     ██║   "
    print "  ╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║███████║███████╗   ██║   "
    print "   ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚══════╝   ╚═╝   "
    print "${NC}"

    if [[ "$show_version" == "true" ]]; then
        local version_line="  ${DIM}Development Environment Setup${NC}  ${CYAN}v${OMNISET_VERSION}${NC}"
        print "$version_line"
    fi

    print ""
}

print_compact_banner() {
    print "${BRIGHT_GREEN}${BOLD}OmniSet${NC} ${DIM}v${OMNISET_VERSION}${NC} - Development Environment Setup"
}

# ═══════════════════════════════════════════════════════════════
# Interactive Elements
# ═══════════════════════════════════════════════════════════════

# Print a yes/no prompt
print_confirm() {
    local message="$1"
    local default="${2:-y}"  # y or n

    if [[ "$default" == "y" ]]; then
        printn "${message} [${BOLD}Y${NC}/n]: "
    else
        printn "${message} [y/${BOLD}N${NC}]: "
    fi
}

# Print a choice menu
print_menu() {
    local title="$1"
    shift
    local -a options=("$@")

    print ""
    print "${BOLD}${title}${NC}"
    print_divider

    local i=1
    for opt in "${options[@]}"; do
        print "  ${BOLD}${i})${NC} ${opt}"
        ((i++))
    done

    print ""
}
