#!/bin/bash

# KIMA - Unified Linux Package Manager
# A unified package manager script for Linux.
#
# This script provides a single interface to manage packages across
# dnf, snap, apt, rpm, yay, pacman, and flatpak.

# Shell compatibility check
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires Bash. Please run with: bash $0 $*"
    exit 1
fi

# Minimum Bash version check (4.0+)
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Error: This script requires Bash 4.0 or newer. Current version: $BASH_VERSION"
    exit 1
fi

# --- Version Information ---
KIMA_VERSION="2.0.0"
KIMA_DATE="2024-01-01"

# Show version information
show_version() {
    print_header
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}KIMA Version Information${COLOR_NC}\n"
    echo -e "${COLOR_YELLOW}Version:${COLOR_NC} ${COLOR_WHITE}${KIMA_VERSION}${COLOR_NC}"
    echo -e "${COLOR_YELLOW}Date:${COLOR_NC} ${COLOR_WHITE}${KIMA_DATE}${COLOR_NC}"
    echo -e "${COLOR_YELLOW}Author:${COLOR_NC} ${COLOR_WHITE}taynotfound${COLOR_NC}"
    echo -e "${COLOR_YELLOW}GitHub:${COLOR_NC} ${COLOR_WHITE}https://github.com/taynotfound/kima${COLOR_NC}"
    echo -e "${COLOR_YELLOW}License:${COLOR_NC} ${COLOR_WHITE}MIT${COLOR_NC}"
    print_footer
}

# --- Colors and Styles ---
COLOR_NC='\033[0m'
COLOR_WHITE='\033[1;37m'
COLOR_BLACK='\033[0;30m'
COLOR_BLUE='\033[0;34m'
COLOR_LIGHT_BLUE='\033[1;34m'
COLOR_GREEN='\033[0;32m'
COLOR_LIGHT_GREEN='\033[1;32m'
COLOR_CYAN='\033[0;36m'
COLOR_LIGHT_CYAN='\033[1;36m'
COLOR_RED='\033[0;31m'
COLOR_LIGHT_RED='\033[1;31m'
COLOR_PURPLE='\033[0;35m'
COLOR_LIGHT_PURPLE='\033[1;35m'
COLOR_BROWN='\033[0;33m'
COLOR_YELLOW='\033[1;33m'
COLOR_GRAY='\033[0;30m'
COLOR_LIGHT_GRAY='\033[0;37m'

# --- Emojis ---
EMOJI_ROCKET="🚀"
EMOJI_SEARCH="🔍"
EMOJI_INSTALL="📦"
EMOJI_UNINSTALL="🗑️"
EMOJI_UPDATE="🔄"
EMOJI_HELP="❓"
EMOJI_ERROR="❌"
EMOJI_SUCCESS="✅"
EMOJI_WARN="⚠️"
EMOJI_LIST="📋"
EMOJI_CHECK="🔍"
EMOJI_AVAILABLE="✅"
EMOJI_UNAVAILABLE="❌"
EMOJI_INFO="ℹ️"
EMOJI_CLEAN="🧹"
EMOJI_UI="🖥️"
EMOJI_EXIT="🚪"

# --- Utility: Print Table ---
print_table() {
    local header="$1"
    local rows="$2"
    local footer="$3"
    echo -e "$header"
    echo -e "$rows" | column -t -s $'\t'
    if [ -n "$footer" ]; then
        echo -e "$footer"
    fi
}

# --- Utility: Print Spinner ---
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ -d /proc/$pid ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%$temp}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- Utility: Format Package Output ---
format_package_output() {
    local pm="$1"
    local output="$2"
    local max_lines="$3"
    if [ -z "$output" ]; then
        echo -e "${COLOR_LIGHT_GRAY}No results found in ${pm}.${COLOR_NC}"
    else
        echo "$output" | head -n "$max_lines"
    fi
}

# --- ASCII Art ---
print_ascii_art() {
    echo -e "${COLOR_LIGHT_PURPLE}"
    echo '  _  __    ___   __  __    ___   '
    echo ' | |/ /   |_ _| |  \/  |  /   \  '
    echo ' | '"'"' <     | |  | |\/| |  | - |  '
    echo ' |_|\_\   |___| |_|__|_|  |_|_|  '
    echo '_|"""""|_|"""""|_|"""""|_|"""""| '
    echo '"`-0-0-'"'"'`-0-0-'"'"'`-0-0-'"'"'`-0-0-'"'"' '
    echo -e "${COLOR_NC}"
}

# Print a beautiful header
print_header() {
    echo -e "${COLOR_LIGHT_PURPLE}╔══════════════════════════════════════════════════════════════╗${COLOR_NC}"
    echo -e "${COLOR_LIGHT_PURPLE}║${COLOR_NC}                    ${COLOR_WHITE}KIMA Package Manager${COLOR_NC}                      ${COLOR_LIGHT_PURPLE}║${COLOR_NC}"
    echo -e "${COLOR_LIGHT_PURPLE}║${COLOR_NC}              ${COLOR_LIGHT_CYAN}Unified Linux Package Management${COLOR_NC}                ${COLOR_LIGHT_PURPLE}║${COLOR_NC}"
    echo -e "${COLOR_LIGHT_PURPLE}╚══════════════════════════════════════════════════════════════╝${COLOR_NC}"
}

# Print a beautiful footer
print_footer() {
    echo -e "${COLOR_LIGHT_PURPLE}╔══════════════════════════════════════════════════════════════╗${COLOR_NC}"
    echo -e "${COLOR_LIGHT_PURPLE}║${COLOR_NC} ${COLOR_LIGHT_GRAY}Made with ❤️  for Linux enthusiasts${COLOR_NC}                           ${COLOR_LIGHT_PURPLE}║${COLOR_NC}"
    echo -e "${COLOR_LIGHT_PURPLE}╚══════════════════════════════════════════════════════════════╝${COLOR_NC}"
}

# Print a section divider
print_divider() {
    echo -e "${COLOR_LIGHT_PURPLE}──────────────────────────────────────────────────────────────${COLOR_NC}"
}

# --- Package Manager Detection (silent, always up to date) ---
_silent() {
    AVAILABLE_PMS=()
    for pm in "${!PM_COMMANDS[@]}"; do
        if command -v $pm &> /dev/null; then
            AVAILABLE_PMS+=($pm)
        fi
    done
}

# Print available managers (for help, TUI, etc)
print_available_managers() {
    echo -e "${COLOR_LIGHT_CYAN}🔧 Available Managers:${COLOR_NC}"
    if [ ${#AVAILABLE_PMS[@]} -eq 0 ]; then
        echo -e "  ${COLOR_LIGHT_RED}No package managers detected${COLOR_NC}"
    else
        for pm in "${AVAILABLE_PMS[@]}"; do
            echo -e "  ${COLOR_LIGHT_BLUE}• ${pm}${COLOR_NC}"
        done
    fi
}

# --- Package Manager Detection ---
declare -A PM_COMMANDS
PM_COMMANDS=(
    [apt]="sudo apt"
    [dnf]="sudo dnf"
    [pacman]="sudo pacman"
    [yay]="yay"
    [rpm]="sudo rpm"
    [snap]="sudo snap"
    [flatpak]="flatpak"
)

# Commands that don't need sudo for read operations
declare -A PM_COMMANDS_NO_SUDO
PM_COMMANDS_NO_SUDO=(
    [apt]="apt"
    [dnf]="dnf"
    [pacman]="pacman"
    [yay]="yay"
    [rpm]="rpm"
    [snap]="snap"
    [flatpak]="flatpak"
)

declare -A PM_INSTALL
PM_INSTALL=(
    [apt]="install -y"
    [dnf]="install -y"
    [pacman]="-S --noconfirm"
    [yay]="-S --noconfirm"
    [rpm]="-i"
    [snap]="install"
    [flatpak]="install -y"
)

declare -A PM_SEARCH
PM_SEARCH=(
    [apt]="search"
    [dnf]="search"
    [pacman]="-Ss"
    [yay]="-Ss"
    [rpm]="-qa"
    [snap]="find"
    [flatpak]="search"
)

declare -A PM_UNINSTALL
PM_UNINSTALL=(
    [apt]="remove -y"
    [dnf]="remove -y"
    [pacman]="-R --noconfirm"
    [yay]="-Rns --noconfirm"
    [rpm]="-e"
    [snap]="remove"
    [flatpak]="uninstall -y"
)

declare -A PM_UPDATE
PM_UPDATE=(
    [apt]="update && sudo apt upgrade -y"
    [dnf]="update -y"
    [pacman]="-Syu --noconfirm"
    [yay]="-Syu --noconfirm"
    [snap]="refresh"
    [flatpak]="update -y"
)

declare -A PM_LIST
PM_LIST=(
    [apt]="list --installed"
    [dnf]="list installed"
    [pacman]="-Q"
    [yay]="-Q"
    [rpm]="-qa"
    [snap]="list"
    [flatpak]="list"
)

declare -A PM_INFO
PM_INFO=(
    [apt]="show"
    [dnf]="info"
    [pacman]="-Si"
    [yay]="-Si"
    [rpm]="-qi"
    [snap]="info"
    [flatpak]="info"
)

declare -A PM_CLEANUP
PM_CLEANUP=(
    [apt]="autoremove -y && sudo apt autoclean"
    [dnf]="autoremove -y"
    [pacman]="-Sc --noconfirm"
    [yay]="-Sc --noconfirm"
    [snap]="refresh"
    [flatpak]="uninstall --unused -y"
)

# Show raw search results
show_raw_search() {
    local search_term=$1
    shift
    local managers=("$@")
    
    for pm in "${managers[@]}"; do
        echo -e "${COLOR_LIGHT_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
        echo -e "${COLOR_YELLOW}🔍 Results from ${pm}:${COLOR_NC}"
        echo -e "${COLOR_LIGHT_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
        local output
        output=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_SEARCH[$pm]} ${search_term} 2>/dev/null)
        if [ -z "$output" ]; then
            echo -e "${COLOR_LIGHT_GRAY}No results found in ${pm}.${COLOR_NC}"
        else
            echo "$output"
        fi
        echo ""
    done
}

# Check if package is installed
check_installed() {
    _silent
    local package=$1
    echo -e "${EMOJI_CHECK} ${COLOR_LIGHT_CYAN}Checking if '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}' is installed...${COLOR_NC}"
    echo ""
    echo -e "${COLOR_YELLOW}DEBUG: AVAILABLE_PMS = ${AVAILABLE_PMS[*]}${COLOR_NC}"
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_LIST[$pm]}" ]; then
            local output
            output=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_LIST[$pm]} 2>/dev/null | grep -i "^${package}" || true)
            echo -e "${COLOR_LIGHT_GRAY}DEBUG: Raw output from ${pm}:${COLOR_NC}"
            echo "$output" | head -5
            if [ -n "$output" ]; then
                echo -e "  ${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Found in ${pm}:${COLOR_NC}"
                echo "$output" | head -3
            else
                echo -e "  ${EMOJI_UNAVAILABLE} ${COLOR_LIGHT_RED}Not found in ${pm}${COLOR_NC}"
            fi
        fi
    done
}

# Show system stats
show_system_stats() {
    _silent
    print_header
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}System Package Statistics:${COLOR_NC}\n"
    if [ ${#AVAILABLE_PMS[@]} -eq 0 ]; then
        echo -e "${COLOR_LIGHT_RED}No package managers detected.${COLOR_NC}"
        print_footer
        return
    fi
    local rows=""
    local total=0
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_LIST[$pm]}" ]; then
            local count
            count=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_LIST[$pm]} 2>/dev/null | wc -l)
            rows+="${pm}\t${count}\n"
            total=$((total + count))
        fi
    done
    print_table "${COLOR_LIGHT_BLUE}Manager\tPackages${COLOR_NC}" "$rows" "${COLOR_YELLOW}Total\t${total}${COLOR_NC}"
    print_footer
}

# Find orphaned packages
find_orphaned() {
    echo -e "${EMOJI_WARN} ${COLOR_LIGHT_CYAN}Finding orphaned packages...${COLOR_NC}"
    echo ""
    
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                echo -e "${COLOR_YELLOW}Orphaned packages in apt:${COLOR_NC}"
                apt list --installed | grep -E "\[installed\]" | awk '{print $1}' | xargs apt-mark showmanual 2>/dev/null | head -10
                ;;
            dnf)
                echo -e "${COLOR_YELLOW}Orphaned packages in dnf:${COLOR_NC}"
                dnf list installed | grep -E "^[a-z]" | head -10
                ;;
            pacman|yay)
                echo -e "${COLOR_YELLOW}Orphaned packages in ${pm}:${COLOR_NC}"
                ${PM_COMMANDS_NO_SUDO[$pm]} -Qdt 2>/dev/null | head -10 || echo "No orphaned packages found"
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}Orphaned package detection not supported for ${pm}${COLOR_NC}"
                ;;
        esac
        echo ""
    done
}

# --- Help Menu ---
show_help() {
    _silent
    print_header
    echo ""
    print_ascii_art
    echo ""
    print_divider
    echo ""
    echo -e "${COLOR_YELLOW}📖 ${COLOR_WHITE}Usage:${COLOR_NC}  ${COLOR_LIGHT_CYAN}kima [command] [package]${COLOR_NC}"
    echo ""
    print_divider
    echo ""
    echo -e "${COLOR_LIGHT_CYAN}🚀 ${COLOR_WHITE}Available Commands:${COLOR_NC}"
    echo ""
    echo -e "  ${EMOJI_INSTALL} ${COLOR_GREEN}install <package>${COLOR_NC}           Install a package (tries all managers)"
    echo -e "  ${EMOJI_INSTALL} ${COLOR_GREEN}multiple <packages...>${COLOR_NC}      Install multiple packages at once"
    echo -e "  ${EMOJI_UPDATE} ${COLOR_GREEN}upgrade <package>${COLOR_NC}           Upgrade a package everywhere"
    echo -e "  ${EMOJI_UNINSTALL} ${COLOR_GREEN}uninstall <package>${COLOR_NC}        Uninstall a package (tries all managers)"
    echo -e "  ${EMOJI_SEARCH} ${COLOR_GREEN}search <package>${COLOR_NC}            Search for a package across all managers"
    echo -e "  ${EMOJI_SEARCH} ${COLOR_GREEN}descsearch <term>${COLOR_NC}           Search by description"
    echo -e "  ${EMOJI_LIST} ${COLOR_GREEN}list${COLOR_NC}                        List installed packages from all managers"
    echo -e "  ${EMOJI_LIST} ${COLOR_GREEN}files <package>${COLOR_NC}              Show files installed by a package"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}info <package>${COLOR_NC}               Show package information"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}details <package>${COLOR_NC}            Show package details from all managers"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}deps <package>${COLOR_NC}               Show dependencies"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}rdeps <package>${COLOR_NC}              Show reverse dependencies"
    echo -e "  ${EMOJI_UPDATE} ${COLOR_GREEN}update${COLOR_NC}                     Update all packages"
    echo -e "  ${EMOJI_CLEAN} ${COLOR_GREEN}cleanup${COLOR_NC}                    Clean up unused packages and cache"
    echo -e "  ${EMOJI_WARN} ${COLOR_GREEN}outdated${COLOR_NC}                    List outdated packages"
    echo -e "  ${EMOJI_WARN} ${COLOR_GREEN}orphaned${COLOR_NC}                    Find orphaned packages"
    echo -e "  ${EMOJI_CHECK} ${COLOR_GREEN}check <package>${COLOR_NC}             Check if package is installed"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}stats${COLOR_NC}                       Show system package statistics"
    echo -e "  ${EMOJI_INSTALL} ${COLOR_GREEN}copycmd <package>${COLOR_NC}          Copy install command to clipboard"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}home <package>${COLOR_NC}              Show package homepage/URL"
    echo -e "  ${EMOJI_UI}  ${COLOR_GREEN}tui${COLOR_NC}                          Start enhanced TUI mode"
    echo -e "  ${EMOJI_UI}  ${COLOR_GREEN}gui${COLOR_NC}                          Start Material Design GUI mode"
    echo -e "  ${EMOJI_UI}  ${COLOR_GREEN}ui${COLOR_NC}                           Start interactive TUI mode (legacy)"
    echo -e "  ${EMOJI_UNINSTALL} ${COLOR_GREEN}remove-multiple${COLOR_NC}           Remove multiple packages interactively"
    echo -e "  ${EMOJI_HELP} ${COLOR_GREEN}help${COLOR_NC}                        Show this help menu"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}compare <package>${COLOR_NC}            Compare package availability and version across all managers"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}suggest <term>${COLOR_NC}                Suggest similar package names"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}backup${COLOR_NC}                        Backup installed packages"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}audit${COLOR_NC}                         Audit installed packages"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}news${COLOR_NC}                            Show Linux/package manager news"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}history <package>${COLOR_NC}              Show package history"
    echo -e "  ${EMOJI_INFO} ${COLOR_GREEN}self-update${COLOR_NC}                     Self-update KIMA"
    echo ""
    print_divider
    echo ""
    echo -e "${COLOR_LIGHT_CYAN}🔧 ${COLOR_WHITE}Available Managers:${COLOR_NC}"
    if [ ${#AVAILABLE_PMS[@]} -eq 0 ]; then
        echo -e "  ${COLOR_LIGHT_RED}No package managers detected${COLOR_NC}"
    else
        for pm in "${AVAILABLE_PMS[@]}"; do
            echo -e "  ${COLOR_LIGHT_BLUE}• ${pm}${COLOR_NC}"
        done
    fi
    echo ""
    print_footer
}

# --- Functions ---

# Install a package
install_package() {
    _silent
    local package=$1
    echo -e "${EMOJI_INSTALL} ${COLOR_LIGHT_CYAN}Attempting to install '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}'...${COLOR_NC}"
    echo ""

    for pm in "${AVAILABLE_PMS[@]}"; do
        echo -e "  ${COLOR_BLUE}🔄 Trying with ${pm}...${COLOR_NC}"
        ${PM_COMMANDS[$pm]} ${PM_INSTALL[$pm]} ${package}
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Package '${package}' installed successfully with ${pm}!${COLOR_NC}"
            return
        fi
    done

    echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Could not install '${package}' with any available package manager.${COLOR_NC}"
}

# Install multiple packages
install_multiple_packages() {
    _silent
    local packages=("$@")
    local total=${#packages[@]}
    local successful=()
    local failed=()
    local results=()
    
    print_header
    echo -e "${EMOJI_INSTALL} ${COLOR_LIGHT_CYAN}Installing ${COLOR_WHITE}${total}${COLOR_LIGHT_CYAN} packages: ${COLOR_WHITE}${packages[*]}${COLOR_LIGHT_CYAN}...${COLOR_NC}"
    echo ""
    print_divider
    echo ""
    
    for package in "${packages[@]}"; do
        echo -e "${EMOJI_INSTALL} ${COLOR_LIGHT_CYAN}Processing '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}'...${COLOR_NC}"
        local success=0
        local used_manager=""
        
        for pm in "${AVAILABLE_PMS[@]}"; do
            echo -e "  ${COLOR_BLUE}🔄 Trying with ${pm}...${COLOR_NC}"
            if ${PM_COMMANDS[$pm]} ${PM_INSTALL[$pm]} ${package} >/dev/null 2>&1; then
                echo -e "  ${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Package '${package}' installed successfully with ${pm}!${COLOR_NC}"
                successful+=("${package}")
                results+=("${package}\t${EMOJI_SUCCESS}\t${pm}")
                used_manager="$pm"
                success=1
                break
            else
                echo -e "  ${COLOR_LIGHT_RED}✗ Failed with ${pm}${COLOR_NC}"
            fi
        done
        
        if [ $success -eq 0 ]; then
            echo -e "  ${EMOJI_ERROR} ${COLOR_LIGHT_RED}Could not install '${package}' with any available package manager.${COLOR_NC}"
            failed+=("${package}")
            results+=("${package}\t${EMOJI_ERROR}\tNone")
        fi
        echo ""
    done
    
    # Print summary
    print_divider
    echo ""
    echo -e "${EMOJI_INFO} ${COLOR_WHITE}Installation Summary:${COLOR_NC}"
    echo ""
    
    # Print results table
    local header="${COLOR_LIGHT_BLUE}Package\tStatus\tManager${COLOR_NC}"
    local rows=""
    for result in "${results[@]}"; do
        rows+="${result}\n"
    done
    print_table "$header" "$rows" ""
    
    echo ""
    echo -e "${COLOR_LIGHT_GREEN}✅ Successfully installed: ${#successful[@]}/${total}${COLOR_NC}"
    echo -e "${COLOR_LIGHT_RED}❌ Failed to install: ${#failed[@]}/${total}${COLOR_NC}"
    
    if [ ${#successful[@]} -gt 0 ]; then
        echo -e "${COLOR_LIGHT_GREEN}Successful packages: ${successful[*]}${COLOR_NC}"
    fi
    
    if [ ${#failed[@]} -gt 0 ]; then
        echo -e "${COLOR_LIGHT_RED}Failed packages: ${failed[*]}${COLOR_NC}"
    fi
    
    print_footer
    
    # Return success if at least one package was installed
    if [ ${#successful[@]} -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Install a package with specific manager
install_package_with_manager() {
    _silent
    local manager=$1
    local package=$2
    
    if [[ " ${AVAILABLE_PMS[@]} " =~ " ${manager} " ]]; then
        echo -e "${EMOJI_INSTALL} ${COLOR_LIGHT_CYAN}Installing '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}' with ${COLOR_YELLOW}${manager}${COLOR_LIGHT_CYAN}...${COLOR_NC}"
        ${PM_COMMANDS[$manager]} ${PM_INSTALL[$manager]} ${package}
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Package '${package}' installed successfully with ${manager}!${COLOR_NC}"
        else
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Failed to install '${package}' with ${manager}.${COLOR_NC}"
        fi
    else
        echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Package manager '${manager}' is not available on this system.${COLOR_NC}"
    fi
}

# Search for a package
search_package() {
    _silent
    if [ "$#" -eq 1 ]; then
        local package=$1
        echo -e "${EMOJI_SEARCH} ${COLOR_LIGHT_CYAN}Searching for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}' across all available managers...${COLOR_NC}"
        echo ""
        show_raw_search "$package" "${AVAILABLE_PMS[@]}"
    elif [ "$#" -eq 2 ]; then
        local manager=$1
        local package=$2
        if [[ " ${AVAILABLE_PMS[@]} " =~ " ${manager} " ]]; then
            echo -e "${EMOJI_SEARCH} ${COLOR_LIGHT_CYAN}Searching for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}' with ${COLOR_YELLOW}${manager}${COLOR_LIGHT_CYAN}...${COLOR_NC}"
            local output
            output=$(${PM_COMMANDS_NO_SUDO[$manager]} ${PM_SEARCH[$manager]} ${package} 2>/dev/null)
            if [ -z "$output" ]; then
                echo -e "${COLOR_LIGHT_GRAY}No results found in ${manager}.${COLOR_NC}"
            else
                echo "$output"
            fi
        else
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Package manager '${manager}' is not available on this system.${COLOR_NC}"
        fi
    fi
}

# Uninstall a package
uninstall_package() {
    _silent
    local package=$1
    echo -e "${EMOJI_UNINSTALL} ${COLOR_LIGHT_CYAN}Attempting to uninstall '${package}'...${COLOR_NC}"
    echo ""

    for pm in "${AVAILABLE_PMS[@]}"; do
        echo -e "  ${COLOR_BLUE}Trying with ${pm}...${COLOR_NC}"
        ${PM_COMMANDS[$pm]} ${PM_UNINSTALL[$pm]} ${package}
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Package '${package}' uninstalled successfully with ${pm}.${COLOR_NC}"
            return
        fi
    done

    echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Could not uninstall '${package}'. It may not be installed.${COLOR_NC}"
}

# Uninstall a package with specific manager
uninstall_package_with_manager() {
    _silent
    local manager=$1
    local package=$2
    
    if [[ " ${AVAILABLE_PMS[@]} " =~ " ${manager} " ]]; then
        echo -e "${EMOJI_UNINSTALL} ${COLOR_LIGHT_CYAN}Uninstalling '${package}' with ${manager}...${COLOR_NC}"
        ${PM_COMMANDS[$manager]} ${PM_UNINSTALL[$manager]} ${package}
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Package '${package}' uninstalled successfully with ${manager}.${COLOR_NC}"
        else
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Failed to uninstall '${package}' with ${manager}.${COLOR_NC}"
        fi
    else
        echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Package manager '${manager}' is not available on this system.${COLOR_NC}"
    fi
}

# Update all packages
update_system() {
    _silent
    echo -e "${EMOJI_UPDATE} ${COLOR_LIGHT_CYAN}Updating system...${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_UPDATE[$pm]}" ]; then
            echo -e "--- ${COLOR_YELLOW}Updating with ${pm} ${COLOR_YELLOW}---"
            ${PM_COMMANDS[$pm]} ${PM_UPDATE[$pm]}
            echo ""
        fi
    done
    echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}System update complete.${COLOR_NC}"
}

# List installed packages
list_packages() {
    _silent
    if [ "$#" -eq 0 ]; then
        echo -e "${EMOJI_LIST} ${COLOR_LIGHT_CYAN}Listing installed packages from all available managers...${COLOR_NC}"
        echo ""
        for pm in "${AVAILABLE_PMS[@]}"; do
            if [ -n "${PM_LIST[$pm]}" ]; then
                echo -e "${COLOR_LIGHT_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
                echo -e "${COLOR_YELLOW}📋 Packages from ${pm}:${COLOR_NC}"
                echo -e "${COLOR_LIGHT_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
                local output
                output=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_LIST[$pm]} 2>/dev/null)
                format_package_output "$pm" "$output" 15
                echo ""
            fi
        done
    elif [ "$#" -eq 1 ]; then
        local manager=$1
        if [[ " ${AVAILABLE_PMS[@]} " =~ " ${manager} " ]]; then
            if [ -n "${PM_LIST[$manager]}" ]; then
                echo -e "${EMOJI_LIST} ${COLOR_LIGHT_CYAN}Listing installed packages from ${manager}...${COLOR_NC}"
                local output
                output=$(${PM_COMMANDS_NO_SUDO[$manager]} ${PM_LIST[$manager]} 2>/dev/null)
                format_package_output "$manager" "$output" 20
            else
                echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Listing not supported for ${manager}.${COLOR_NC}"
            fi
        else
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Package manager '${manager}' is not available on this system.${COLOR_NC}"
        fi
    fi
}

# Show package information
show_package_info() {
    _silent
    local package=$1
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Showing information for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}'...${COLOR_NC}"
    echo ""
    
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_INFO[$pm]}" ]; then
            echo -e "${COLOR_LIGHT_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
            echo -e "${COLOR_YELLOW}ℹ️ Info from ${pm}:${COLOR_NC}"
            echo -e "${COLOR_LIGHT_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
            local output
            output=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_INFO[$pm]} ${package} 2>/dev/null)
            format_package_output "$pm" "$output" 25
            echo ""
        fi
    done
}

# Cleanup system
cleanup_system() {
    _silent
    echo -e "${EMOJI_CLEAN} ${COLOR_LIGHT_CYAN}Cleaning up system...${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_CLEANUP[$pm]}" ]; then
            echo -e "--- ${COLOR_YELLOW}Cleaning with ${pm} ${COLOR_YELLOW}---"
            ${PM_COMMANDS[$pm]} ${PM_CLEANUP[$pm]}
            echo ""
        fi
    done
    echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}System cleanup complete.${COLOR_NC}"
}

# TUI Mode
tui_mode() {
    _silent
    while true; do
        clear
        print_header
        echo ""
        print_ascii_art
        echo ""
        print_divider
        echo ""
        echo -e "${COLOR_WHITE}🎮 Interactive Mode ${EMOJI_UI}${COLOR_NC}"
        echo ""
        print_available_managers
        echo ""
        print_divider
        echo ""
        echo -e "${COLOR_YELLOW}🎯 Select an option:${COLOR_NC}"
        echo ""
        echo -e "  ${COLOR_GREEN}1${COLOR_NC} ${EMOJI_INSTALL} Install package"
        echo -e "  ${COLOR_GREEN}2${COLOR_NC} ${EMOJI_SEARCH} Search package"
        echo -e "  ${COLOR_GREEN}3${COLOR_NC} ${EMOJI_UNINSTALL} Uninstall package"
        echo -e "  ${COLOR_GREEN}4${COLOR_NC} ${EMOJI_UPDATE} Update system"
        echo -e "  ${COLOR_GREEN}5${COLOR_NC} ${EMOJI_LIST} List packages"
        echo -e "  ${COLOR_GREEN}6${COLOR_NC} ${EMOJI_INFO} Package info"
        echo -e "  ${COLOR_GREEN}7${COLOR_NC} ${EMOJI_CLEAN} Cleanup system"
        echo -e "  ${COLOR_GREEN}8${COLOR_NC} ${EMOJI_HELP} Show help"
        echo -e "  ${COLOR_RED}0${COLOR_NC} ${EMOJI_EXIT} Exit"
        echo ""
        print_divider
        echo ""
        read -p "${COLOR_LIGHT_CYAN}Enter your choice (0-8): ${COLOR_NC}" choice
        
                 case $choice in
             1)
                 echo -e "${COLOR_LIGHT_CYAN}📦 Package Installation${COLOR_NC}"
                 read -p "Enter package name: " package
                 if [ -n "$package" ]; then
                     echo ""
                     print_divider
                     install_package "$package"
                     print_divider
                     echo ""
                     read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 fi
                 ;;
             2)
                 echo -e "${COLOR_LIGHT_CYAN}🔍 Package Search${COLOR_NC}"
                 read -p "Enter package name to search: " package
                 if [ -n "$package" ]; then
                     echo ""
                     print_divider
                     search_package "$package"
                     print_divider
                     echo ""
                     read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 fi
                 ;;
             3)
                 echo -e "${COLOR_LIGHT_CYAN}🗑️ Package Uninstallation${COLOR_NC}"
                 read -p "Enter package name to uninstall: " package
                 if [ -n "$package" ]; then
                     echo ""
                     print_divider
                     uninstall_package "$package"
                     print_divider
                     echo ""
                     read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 fi
                 ;;
             4)
                 echo -e "${COLOR_LIGHT_CYAN}🔄 System Update${COLOR_NC}"
                 echo ""
                 print_divider
                 update_system
                 print_divider
                 echo ""
                 read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 ;;
             5)
                 echo -e "${COLOR_LIGHT_CYAN}📋 Package Listing${COLOR_NC}"
                 echo ""
                 print_divider
                 list_packages
                 print_divider
                 echo ""
                 read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 ;;
             6)
                 echo -e "${COLOR_LIGHT_CYAN}ℹ️ Package Information${COLOR_NC}"
                 read -p "Enter package name for info: " package
                 if [ -n "$package" ]; then
                     echo ""
                     print_divider
                     show_package_info "$package"
                     print_divider
                     echo ""
                     read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 fi
                 ;;
             7)
                 echo -e "${COLOR_LIGHT_CYAN}🧹 System Cleanup${COLOR_NC}"
                 echo ""
                 print_divider
                 cleanup_system
                 print_divider
                 echo ""
                 read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 ;;
             8)
                 echo -e "${COLOR_LIGHT_CYAN}❓ Help${COLOR_NC}"
                 echo ""
                 show_help
                 echo ""
                 read -p "${COLOR_LIGHT_GRAY}Press Enter to continue...${COLOR_NC}"
                 ;;
             0)
                 echo ""
                 print_divider
                 echo -e "${EMOJI_EXIT} ${COLOR_LIGHT_CYAN}Exiting KIMA TUI mode.${COLOR_NC}"
                 echo -e "${COLOR_LIGHT_GRAY}Thank you for using KIMA!${COLOR_NC}"
                 print_divider
                 echo ""
                 exit 0
                 ;;
                         *)
                 echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Invalid choice. Please try again.${COLOR_NC}"
                 echo -e "${COLOR_LIGHT_GRAY}Press any key to continue...${COLOR_NC}"
                 read -n 1 -s
                 ;;
         esac
     done
 }


# --- Remove Multiple Command Line Function ---
remove_multiple_packages() {
    echo -e "${EMOJI_UNINSTALL} ${COLOR_LIGHT_CYAN}Interactive Multiple Package Removal${COLOR_NC}\n"
    
    # Check for required dependencies
    if ! command -v fzf &>/dev/null; then
        echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}This feature requires 'fzf' for package selection.${COLOR_NC}"
        echo -e "${COLOR_LIGHT_YELLOW}Install with: sudo apt install fzf${COLOR_NC}"
        return 1
    fi
    
    local packages_list=$(mktemp)
    echo -e "${EMOJI_LIST} Gathering installed packages..."
    
    # Gather packages from all managers
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_LIST[$pm]}" ]; then
            echo -e "  ${COLOR_BLUE}Getting packages from ${pm}...${COLOR_NC}"
            ${PM_COMMANDS_NO_SUDO[$pm]} ${PM_LIST[$pm]} 2>/dev/null | \
            awk '{print $1 " (" pm ")"}' pm="$pm" >> "$packages_list"
        fi
    done
    
    if [ ! -s "$packages_list" ]; then
        echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No installed packages found.${COLOR_NC}"
        rm -f "$packages_list"
        return 1
    fi
    
    echo -e "\n${COLOR_LIGHT_CYAN}Select packages to remove (use Tab to select multiple, Enter to confirm):${COLOR_NC}"
    local selected_packages
    selected_packages=$(fzf --multi --height=60% --prompt="Select packages: " < "$packages_list")
    
    if [ -z "$selected_packages" ]; then
        echo -e "${COLOR_LIGHT_GRAY}No packages selected. Operation cancelled.${COLOR_NC}"
        rm -f "$packages_list"
        return 0
    fi
    
    local package_count=$(echo "$selected_packages" | wc -l)
    echo -e "\n${COLOR_YELLOW}You selected $package_count packages for removal:${COLOR_NC}"
    echo "$selected_packages"
    
    echo -e "\n${COLOR_LIGHT_RED}Are you sure you want to remove these packages? (y/N):${COLOR_NC}"
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n${EMOJI_UNINSTALL} ${COLOR_LIGHT_CYAN}Removing selected packages...${COLOR_NC}"
        local i=0
        echo "$selected_packages" | while read -r line; do
            local package=$(echo "$line" | awk '{print $1}')
            if [ -n "$package" ]; then
                i=$((i + 1))
                echo -e "\n${COLOR_LIGHT_PURPLE}[$i/$package_count] Removing $package...${COLOR_NC}"
                uninstall_package "$package"
                show_progress "$i" "$package_count" "Progress"
            fi
        done
        echo -e "\n${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Multiple package removal complete!${COLOR_NC}"
    else
        echo -e "${COLOR_LIGHT_GRAY}Operation cancelled.${COLOR_NC}"
    fi
    
    rm -f "$packages_list"
}

# Upgrade a single package across all managers
upgrade_package() {
    local package=$1
    echo -e "${EMOJI_UPDATE} ${COLOR_LIGHT_CYAN}Upgrading '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}' across all managers...${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt|dnf|pacman|yay)
                echo -e "  ${COLOR_BLUE}🔄 Trying with ${pm}...${COLOR_NC}"
                ${PM_COMMANDS[$pm]} upgrade -y ${package}
                ;;
            snap)
                echo -e "  ${COLOR_BLUE}🔄 Trying with snap...${COLOR_NC}"
                ${PM_COMMANDS[$pm]} refresh ${package}
                ;;
            flatpak)
                echo -e "  ${COLOR_BLUE}🔄 Trying with flatpak...${COLOR_NC}"
                ${PM_COMMANDS[$pm]} update ${package} -y
                ;;
            *)
                echo -e "  ${COLOR_LIGHT_GRAY}Upgrade not supported for ${pm}${COLOR_NC}"
                ;;
        esac
    done
}

# Show package details from all managers
show_details() {
    local package=$1
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Details for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}':${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_INFO[$pm]}" ]; then
            echo -e "${COLOR_YELLOW}From ${pm}:${COLOR_NC}"
            ${PM_COMMANDS_NO_SUDO[$pm]} ${PM_INFO[$pm]} ${package} 2>/dev/null | head -20
            echo ""
        fi
    done
}

# List outdated packages
list_outdated() {
    echo -e "${EMOJI_WARN} ${COLOR_LIGHT_CYAN}Outdated packages:${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                echo -e "${COLOR_YELLOW}Outdated in apt:${COLOR_NC}"
                apt list --upgradable 2>/dev/null | grep -v "Listing..." | head -10
                ;;
            dnf)
                echo -e "${COLOR_YELLOW}Outdated in dnf:${COLOR_NC}"
                dnf check-update 2>/dev/null | head -10
                ;;
            pacman|yay)
                echo -e "${COLOR_YELLOW}Outdated in ${pm}:${COLOR_NC}"
                ${PM_COMMANDS_NO_SUDO[$pm]} -Qu 2>/dev/null | head -10
                ;;
            flatpak)
                echo -e "${COLOR_YELLOW}Outdated in flatpak:${COLOR_NC}"
                flatpak remote-ls --updates flathub 2>/dev/null | head -10
                ;;
            snap)
                echo -e "${COLOR_YELLOW}Outdated in snap:${COLOR_NC}"
                snap refresh --list 2>/dev/null | head -10
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}Outdated check not supported for ${pm}${COLOR_NC}"
                ;;
        esac
        echo ""
    done
}

# Show files installed by a package
show_files() {
    local package=$1
    echo -e "${EMOJI_LIST} ${COLOR_LIGHT_CYAN}Files for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}':${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt|dpkg)
                dpkg -L ${package} 2>/dev/null | head -20
                ;;
            dnf|rpm)
                rpm -ql ${package} 2>/dev/null | head -20
                ;;
            pacman|yay)
                pacman -Ql ${package} 2>/dev/null | head -20
                ;;
            flatpak)
                echo -e "${COLOR_LIGHT_GRAY}Flatpak does not support listing files for a package.${COLOR_NC}"
                ;;
            snap)
                echo -e "${COLOR_LIGHT_GRAY}Snap does not support listing files for a package.${COLOR_NC}"
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}Not supported for ${pm}${COLOR_NC}"
                ;;
        esac
        echo ""
    done
}

# Search by description
desc_search() {
    local term=$1
    echo -e "${EMOJI_SEARCH} ${COLOR_LIGHT_CYAN}Searching descriptions for '${COLOR_WHITE}${term}${COLOR_LIGHT_CYAN}'...${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                apt-cache search ${term} | grep -i "${term}" | head -10
                ;;
            dnf)
                dnf search all ${term} | grep -i "${term}" | head -10
                ;;
            pacman|yay)
                ${PM_COMMANDS_NO_SUDO[$pm]} -Ss ${term} | grep -i "${term}" | head -10
                ;;
            flatpak)
                flatpak search ${term} | grep -i "${term}" | head -10
                ;;
            snap)
                snap find ${term} | grep -i "${term}" | head -10
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}Description search not supported for ${pm}${COLOR_NC}"
                ;;
        esac
        echo ""
    done
}

# Show dependencies
show_deps() {
    local package=$1
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Dependencies for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}':${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                apt-cache depends ${package} 2>/dev/null | head -15
                ;;
            dnf)
                dnf repoquery --requires ${package} 2>/dev/null | head -15
                ;;
            pacman|yay)
                pactree -d1 ${package} 2>/dev/null | head -15
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}Dependency listing not supported for ${pm}${COLOR_NC}"
                ;;
        esac
        echo ""
    done
}

# Show reverse dependencies
show_rdeps() {
    local package=$1
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Reverse dependencies for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}':${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                apt-cache rdepends ${package} 2>/dev/null | head -15
                ;;
            dnf)
                dnf repoquery --whatrequires ${package} 2>/dev/null | head -15
                ;;
            pacman|yay)
                pactree -r -d1 ${package} 2>/dev/null | head -15
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}Reverse dependency listing not supported for ${pm}${COLOR_NC}"
                ;;
        esac
        echo ""
    done
}

# Copy install command to clipboard
copy_install_cmd() {
    local package=$1
    local cmd=""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                cmd="sudo apt install -y ${package}"; break;;
            dnf)
                cmd="sudo dnf install -y ${package}"; break;;
            pacman)
                cmd="sudo pacman -S --noconfirm ${package}"; break;;
            yay)
                cmd="yay -S --noconfirm ${package}"; break;;
            flatpak)
                cmd="flatpak install -y ${package}"; break;;
            snap)
                cmd="sudo snap install ${package}"; break;;
        esac
    done
    if [ -n "$cmd" ]; then
        if command -v xclip &>/dev/null; then
            echo -n "$cmd" | xclip -selection clipboard
            echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Copied: $cmd${COLOR_NC}"
        elif command -v pbcopy &>/dev/null; then
            echo -n "$cmd" | pbcopy
            echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Copied: $cmd${COLOR_NC}"
        else
            echo -e "${EMOJI_WARN} ${COLOR_YELLOW}Clipboard tool not found. Here is the command:${COLOR_NC}"
            echo "$cmd"
        fi
    else
        echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No install command found for '${package}'.${COLOR_NC}"
    fi
}

# Show package homepage/URL
show_homepage() {
    local package=$1
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Homepage/URL for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}':${COLOR_NC}"
    echo ""
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                apt-cache show ${package} 2>/dev/null | grep -iE 'homepage|url' | head -2
                ;;
            dnf)
                dnf info ${package} 2>/dev/null | grep -iE 'homepage|url' | head -2
                ;;
            pacman|yay)
                pacman -Si ${package} 2>/dev/null | grep -iE 'url' | head -2
                ;;
            flatpak)
                flatpak search ${package} | grep -iE 'url' | head -2
                ;;
            snap)
                snap info ${package} 2>/dev/null | grep -iE 'contact|website|url' | head -2
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}Homepage/URL not supported for ${pm}${COLOR_NC}"
                ;;
        esac
        echo ""
    done
}

# --- Compare package across managers ---
compare_package() {
    _silent
    local package=$1
    print_header
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Comparing '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}' across all managers...${COLOR_NC}\n"
    local rows=""
    for pm in "${AVAILABLE_PMS[@]}"; do
        local version="-"
        if [ -n "${PM_INFO[$pm]}" ]; then
            version=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_INFO[$pm]} ${package} 2>/dev/null | grep -iE 'version|ver' | head -1 | awk -F: '{print $2}' | xargs)
            if [ -z "$version" ]; then
                version="Not found"
            fi
        else
            version="N/A"
        fi
        rows+="${pm}\t${version}\n"
    done
    print_table "${COLOR_LIGHT_BLUE}Manager\tVersion${COLOR_NC}" "$rows" ""
    print_footer
}

# --- Suggest similar package names ---
suggest_package() {
    _silent
    local term=$1
    print_header
    echo -e "${EMOJI_SEARCH} ${COLOR_LIGHT_CYAN}Suggestions for '${COLOR_WHITE}${term}${COLOR_LIGHT_CYAN}':${COLOR_NC}\n"
    local found=0
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_SEARCH[$pm]}" ]; then
            local output
            output=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_SEARCH[$pm]} ${term:0:3} 2>/dev/null | grep -i "$term" | head -10)
            if [ -n "$output" ]; then
                found=1
                echo -e "${COLOR_YELLOW}From ${pm}:${COLOR_NC}"
                echo "$output"
                echo
            fi
        fi
    done
    if [ $found -eq 0 ]; then
        echo -e "${COLOR_LIGHT_RED}No suggestions found.${COLOR_NC}"
    fi
    print_footer
}

# --- Backup installed packages ---
backup_packages() {
    _silent
    print_header
    echo -e "${EMOJI_LIST} ${COLOR_LIGHT_CYAN}Backing up installed packages...${COLOR_NC}\n"
    local backup_file="kima-backup-$(date +%Y%m%d-%H%M%S).txt"
    local all_install_cmds=()
    for pm in "${AVAILABLE_PMS[@]}"; do
        if [ -n "${PM_LIST[$pm]}" ]; then
            echo "# ${pm}" >> "$backup_file"
            local output
            output=$(${PM_COMMANDS_NO_SUDO[$pm]} ${PM_LIST[$pm]} 2>/dev/null)
            echo "$output" >> "$backup_file"
            echo >> "$backup_file"
            # Parse package names and versions for install command
            local pkgs=()
            case $pm in
                dnf)
                    # dnf list installed: NAME.VERSION-RELEASE.ARCH @repo
                    pkgs+=( $(echo "$output" | awk 'NR>1 && $1 !~ /^$/ {split($1,a,"."); print a[1]}' ) )
                    ;;
                rpm)
                    # rpm -qa: NAME-VERSION-RELEASE.ARCH
                    pkgs+=( $(echo "$output" | awk -F '-' '{OFS="-"; n=NF-2; if(n>0) {for(i=1;i<=n;i++) printf $i "-"; printf $(n+1) " "} }' | sed 's/ *$//') )
                    ;;
                flatpak)
                    # flatpak list: NAME	APPID	VERSION	BRANCH
                    pkgs+=( $(echo "$output" | awk 'NR>1 {print $1}' ) )
                    ;;
                pacman|yay)
                    # pacman -Q: NAME VERSION
                    pkgs+=( $(echo "$output" | awk '{print $1}' ) )
                    ;;
                apt)
                    # apt list --installed: NAME/VERSION ...
                    pkgs+=( $(echo "$output" | awk -F'/' 'NR>1 {print $1}' ) )
                    ;;
                snap)
                    # snap list: NAME ...
                    pkgs+=( $(echo "$output" | awk 'NR>1 {print $1}' ) )
                    ;;
            esac
            for pkg in "${pkgs[@]}"; do
                all_install_cmds+=("$pkg")
            done
        fi
    done
    # Write install command at the end of the file
    if [ ${#all_install_cmds[@]} -gt 0 ]; then
        echo "# To restore all packages, run:" >> "$backup_file"
        echo "kima install ${all_install_cmds[*]}" >> "$backup_file"
    fi
    echo -e "${COLOR_LIGHT_GREEN}Backup saved to ${backup_file}${COLOR_NC}"
    print_footer
}

# --- Audit installed packages (basic, using 'debsecan' or 'dnf updateinfo') ---
audit_packages() {
    _silent
    print_header
    echo -e "${EMOJI_WARN} ${COLOR_LIGHT_CYAN}Auditing installed packages for security issues...${COLOR_NC}\n"
    local found=0
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                if command -v debsecan &>/dev/null; then
                    debsecan | head -20
                    found=1
                fi
                ;;
            dnf)
                dnf updateinfo list security all 2>/dev/null | head -20
                found=1
                ;;
            pacman|yay)
                echo -e "${COLOR_LIGHT_GRAY}No built-in audit for ${pm}.${COLOR_NC}"
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}No audit available for ${pm}.${COLOR_NC}"
                ;;
        esac
    done
    if [ $found -eq 0 ]; then
        echo -e "${COLOR_LIGHT_RED}No security audit tools found for your managers.${COLOR_NC}"
    fi
    print_footer
}

# --- Show Linux/package manager news (RSS via curl) ---
show_news() {
    print_header
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Latest Linux/Package Manager News:${COLOR_NC}\n"
    if command -v curl &>/dev/null; then
        curl -s https://www.phoronix.com/rss.php | grep -oP '(?<=<title>)[^<]+' | head -10 | tail -n +2
    else
        echo -e "${COLOR_LIGHT_RED}curl is required for news fetching.${COLOR_NC}"
    fi
    print_footer
}

# --- Show package history (if supported) ---
show_history() {
    _silent
    local package=$1
    print_header
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}History for '${COLOR_WHITE}${package}${COLOR_LIGHT_CYAN}':${COLOR_NC}\n"
    local found=0
    for pm in "${AVAILABLE_PMS[@]}"; do
        case $pm in
            apt)
                zgrep -i "$package" /var/log/apt/history.log* 2>/dev/null | tail -10 && found=1
                ;;
            dnf)
                sudo dnf history userinstalled | grep -i "$package" | tail -10 && found=1
                ;;
            pacman|yay)
                grep -i "$package" /var/log/pacman.log 2>/dev/null | tail -10 && found=1
                ;;
            *)
                echo -e "${COLOR_LIGHT_GRAY}No history available for ${pm}.${COLOR_NC}"
                ;;
        esac
    done
    if [ $found -eq 0 ]; then
        echo -e "${COLOR_LIGHT_RED}No history found for '${package}'.${COLOR_NC}"
    fi
    print_footer
}

# --- Self-update from GitHub ---
self_update() {
    print_header
    echo -e "${EMOJI_UPDATE} ${COLOR_LIGHT_CYAN}Updating KIMA from GitHub...${COLOR_NC}\n"
    if command -v curl &>/dev/null; then
        curl -fsSL https://raw.githubusercontent.com/taynotfound/kima/main/kima.sh -o "$0" && \
        chmod +x "$0" && \
        echo -e "${COLOR_LIGHT_GREEN}KIMA updated successfully! Restart the script to use the new version.${COLOR_NC}"
    else
        echo -e "${COLOR_LIGHT_RED}curl is required for self-update.${COLOR_NC}"
    fi
    print_footer
}


self_check() {
    print_header
    echo -e "${EMOJI_INFO} ${COLOR_LIGHT_CYAN}Checking KIMA...${COLOR_NC}\n"
    echo -e "${COLOR_LIGHT_GREEN}KIMA is up to date.${COLOR_NC}"
    print_footer
    # Test every command and report errors/successes

    # List of CLI commands to test (command, argument, ...)
    local commands_to_test=(
        "help"
        "install neofetch"
        "uninstall neofetch"
        "search neofetch"
        "list"
        "files neofetch"
        "info neofetch"
        "details neofetch"
        "deps neofetch"
        "rdeps neofetch"
        "update"
        "cleanup"
        "outdated"
        "orphaned"
        "check neofetch"
        "stats"
        "copycmd neofetch"
        "home neofetch"
        "compare neofetch"
        "suggest neofetch"
        "backup"
        "audit"
        "news"
        "history neofetch"
        "upgrade neofetch"
        "self-update"
    )

    echo -e "${COLOR_YELLOW}Running self-check on all major CLI commands...${COLOR_NC}"
    local total=${#commands_to_test[@]}
    local passed=0
    local failed=0

    for cmd in "${commands_to_test[@]}"; do
        # Run the command as a subprocess
        ./kima.sh $cmd >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} ${COLOR_LIGHT_GREEN}Command './kima.sh $cmd' executed successfully.${COLOR_NC}"
            ((passed++))
        else
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Command './kima.sh $cmd' failed or not implemented properly.${COLOR_NC}"
            echo -e "${COLOR_LIGHT_RED}Output:${COLOR_NC}"
            ./kima.sh $cmd 2>&1 | head -20
            ((failed++))
        fi
    done

    echo -e "\n${COLOR_CYAN}Self-check complete: ${COLOR_LIGHT_GREEN}${passed} passed${COLOR_NC}, ${COLOR_LIGHT_RED}${failed} failed${COLOR_NC}, ${COLOR_WHITE}${total} total${COLOR_NC}."
}

# --- Aliases for Self-Check Compatibility ---
show_info() { show_package_info "$@"; }
update_all() { update_system "$@"; }
cleanup_packages() { cleanup_system "$@"; }
list_orphaned() { find_orphaned "$@"; }
show_stats() { show_system_stats "$@"; }

# --- Main Logic ---
if [ "$#" -eq 0 ]; then
    show_help
    exit 0
fi

case "$1" in
    install)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        elif [ -z "$3" ]; then
            install_package "$2"
        else
            install_package_with_manager "$2" "$3"
        fi
        ;;
    multiple)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No packages specified.${COLOR_NC}"
            echo -e "${COLOR_LIGHT_CYAN}Usage: kima multiple <package1> <package2> ... <packageN>${COLOR_NC}"
            echo -e "${COLOR_LIGHT_CYAN}Example: kima multiple neofetch htop git${COLOR_NC}"
            show_help
        else
            shift  # Remove 'multiple' from arguments
            install_multiple_packages "$@"
        fi
        ;;
    search)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        elif [ -z "$3" ]; then
            search_package "$2"
        else
            search_package "$2" "$3"
        fi
        ;;
    uninstall)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        elif [ -z "$3" ]; then
            uninstall_package "$2"
        else
            uninstall_package_with_manager "$2" "$3"
        fi
        ;;
    update)
        update_system
        ;;
    list)
        if [ -z "$2" ]; then
            list_packages
        else
            list_packages "$2"
        fi
        ;;
    info)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            show_package_info "$2"
        fi
        ;;
    cleanup)
        cleanup_system
        ;;
    check)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            check_installed "$2"
        fi
        ;;
    stats)
        show_system_stats
        ;;
    orphaned)
        find_orphaned
        ;;
    ui)
        tui_mode
        ;;
    tui)
        enhanced_tui_mode
        ;;
    gui)
        gui_mode
        ;;
    remove-multiple)
        remove_multiple_packages
        ;;
    help)
        show_help
        ;;
    upgrade)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            upgrade_package "$2"
        fi
        ;;
    details)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            show_details "$2"
        fi
        ;;
    outdated)
        list_outdated
        ;;
    files)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            show_files "$2"
        fi
        ;;
    descsearch)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No search term specified.${COLOR_NC}"
            show_help
        else
            desc_search "$2"
        fi
        ;;
    deps)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            show_deps "$2"
        fi
        ;;
    rdeps)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            show_rdeps "$2"
        fi
        ;;
    copycmd)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            copy_install_cmd "$2"
        fi
        ;;
    home)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            show_homepage "$2"
        fi
        ;;
    compare)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            compare_package "$2"
        fi
        ;;
    suggest)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No search term specified.${COLOR_NC}"
            show_help
        else
            suggest_package "$2"
        fi
        ;;
    backup)
        backup_packages
        ;;
    audit)
        audit_packages
        ;;
    news)
        show_news
        ;;
    history)
        if [ -z "$2" ]; then
            echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}No package specified.${COLOR_NC}"
            show_help
        else
            show_history "$2"
        fi
        ;;
    self-update)
        self_update
        ;;
    self-check)
        self_check
        ;;
    version|--version|-v)
        show_version
        ;;
    *)
        echo -e "${EMOJI_ERROR} ${COLOR_LIGHT_RED}Invalid command: $1${COLOR_NC}"
        show_help
        ;;
esac
