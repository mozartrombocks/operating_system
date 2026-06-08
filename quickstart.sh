#!/bin/bash

################################################################################
# @file quickstart.sh
# @brief Quick start script for OS kernel development
#
# One-command setup and verification for new developers.
#
# Usage:
#   ./quickstart.sh              # Interactive mode
#   ./quickstart.sh --verify     # Only check prerequisites
#   ./quickstart.sh --build      # Build kernel
#   ./quickstart.sh --test       # Run tests
#   ./quickstart.sh --all        # Do everything
#   ./quickstart.sh --help       # Show help
#
# This script:
#   1. Checks system prerequisites
#   2. Installs missing dependencies (with prompt)
#   3. Builds the kernel
#   4. Optionally runs tests
#   5. Shows next steps
################################################################################

set -euo pipefail

# ============================================================================
# COLORS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_NAME="OS Kernel"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    printf "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${BLUE}║ %-62s │${NC}\n" "$1"
    printf "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    printf "${YELLOW}▶ $1${NC}\n"
}

print_success() {
    printf "${GREEN}✓ $1${NC}\n"
}

print_error() {
    printf "${RED}✗ $1${NC}\n"
}

print_info() {
    printf "${BLUE}ℹ $1${NC}\n"
}

confirm() {
    local prompt="$1"
    local response

    read -p "$(printf "${YELLOW}$prompt (y/n): ${NC}"))" response
    [[ "$response" == "y" || "$response" == "Y" ]]
}

# ============================================================================
# PREREQUISITES CHECK
# ============================================================================

check_prerequisites() {
    print_section "Checking Prerequisites"

    local missing=()

    # Check each required tool
    if ! command -v gcc &> /dev/null; then
        missing+=("gcc")
    else
        print_success "gcc found ($(gcc --version | head -1))"
    fi

    if ! command -v nasm &> /dev/null; then
        missing+=("nasm")
    else
        print_success "nasm found ($(nasm -version | head -1))"
    fi

    if ! command -v make &> /dev/null; then
        missing+=("make")
    else
        print_success "make found ($(make --version | head -1 | cut -d' ' -f3-))"
    fi

    if ! command -v qemu-system-x86_64 &> /dev/null; then
        missing+=("qemu-system-x86")
    else
        print_success "qemu-system-x86_64 found"
    fi

    if ! command -v gdb &> /dev/null; then
        missing+=("gdb")
    else
        print_success "gdb found ($(gdb --version | head -1))"
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    else
        print_success "git found ($(git --version))"
    fi

    if ! command -v xorriso &> /dev/null; then
        missing+=("xorriso")
    else
        print_success "xorriso found"
    fi

    if ! command -v grub-mkrescue &> /dev/null; then
        missing+=("grub-common")
    else
        print_success "grub-common found"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        printf "\n"
        print_error "Missing prerequisites: ${missing[*]}"
        return 1
    else
        printf "\n"
        print_success "All prerequisites found!"
        return 0
    fi
}

# ============================================================================
# DEPENDENCY INSTALLATION
# ============================================================================

install_dependencies() {
    print_section "Installing Missing Dependencies"

    if confirm "Install missing dependencies? This requires sudo."; then
        if ! command -v apt-get &> /dev/null; then
            print_error "apt-get not found. Please install dependencies manually."
            print_info "See PLATFORM_REQUIREMENTS.md for instructions"
            return 1
        fi

        print_info "Running: sudo apt-get update"
        sudo apt-get update || return 1

        print_info "Running: sudo apt-get install build-essential nasm qemu-system-x86 gdb git xorriso grub-common"
        sudo apt-get install -y build-essential nasm qemu-system-x86 gdb git xorriso grub-common || return 1

        print_success "Dependencies installed!"
        return 0
    else
        print_info "Skipped dependency installation"
        return 1
    fi
}

# ============================================================================
# BUILD KERNEL
# ============================================================================

build_kernel() {
    print_section "Building Kernel"

    cd "$PROJECT_DIR"

    if ! make build-x86_64; then
        print_error "Kernel build failed!"
        return 1
    fi

    print_success "Kernel built successfully!"
    return 0
}

# ============================================================================
# RUN TESTS
# ============================================================================

run_tests() {
    print_section "Running Tests"

    cd "$PROJECT_DIR"

    if [ ! -f "Makefile.testing" ]; then
        print_info "Testing not configured yet"
        return 0
    fi

    if ! make -f Makefile.testing test; then
        print_error "Some tests failed"
        return 1
    fi

    print_success "All tests passed!"
    return 0
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_menu() {
    printf "\n"
    printf "${BLUE}Available Options:${NC}\n"
    printf "  1. Check prerequisites only\n"
    printf "  2. Install dependencies\n"
    printf "  3. Build kernel\n"
    printf "  4. Run tests\n"
    printf "  5. Do everything (full setup)\n"
    printf "  6. Show more information\n"
    printf "  0. Exit\n"
    printf "\n"
}

show_help() {
    cat << EOF
${BLUE}${PROJECT_NAME} - Quick Start${NC}

Usage:
  $0 [OPTION]

Options:
  --verify              Check prerequisites only
  --install             Install missing dependencies
  --build               Build kernel
  --test                Run tests
  --all                 Do everything (full setup)
  --help                Show this help message

Examples:
  $0                    # Interactive menu
  $0 --verify           # Check prerequisites
  $0 --all              # Full setup (check, install, build, test)

After successful setup, try:
  make help             # Show all make targets
  make emulate          # Run kernel in QEMU
  make debug            # Debug with GDB

See DEVELOPMENT.md for more information.

EOF
}

# ============================================================================
# MAIN PROGRAM
# ============================================================================

main() {
    # Parse command line arguments
    if [ $# -gt 0 ]; then
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --verify)
                print_header "Verifying Prerequisites"
                check_prerequisites
                exit $?
                ;;
            --install)
                print_header "Installing Dependencies"
                check_prerequisites || install_dependencies
                exit $?
                ;;
            --build)
                print_header "Building Kernel"
                build_kernel
                exit $?
                ;;
            --test)
                print_header "Running Tests"
                run_tests
                exit $?
                ;;
            --all)
                print_header "$PROJECT_NAME - Quick Start (Full Setup)"

                check_prerequisites || {
                    print_info "Missing prerequisites"
                    install_dependencies || exit 1
                }

                build_kernel || exit 1
                run_tests || true  # Don't exit on test failure

                print_header "Setup Complete!"
                printf "\n"
                printf "${GREEN}Next steps:${NC}\n"
                printf "  cd ${PROJECT_DIR}\n"
                printf "  make emulate          # Run kernel\n"
                printf "  make debug            # Debug with GDB\n"
                printf "  make help             # See all targets\n"
                printf "\n"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    fi

    # Interactive menu
    print_header "$PROJECT_NAME - Quick Start"

    while true; do
        show_menu
        read -p "$(printf "${YELLOW}Select option: ${NC}")" choice

        case "$choice" in
            1)
                print_header "Checking Prerequisites"
                check_prerequisites
                ;;
            2)
                print_header "Installing Dependencies"
                check_prerequisites || install_dependencies
                ;;
            3)
                print_header "Building Kernel"
                build_kernel
                ;;
            4)
                print_header "Running Tests"
                run_tests
                ;;
            5)
                print_header "$PROJECT_NAME - Full Setup"

                check_prerequisites || {
                    print_info "Missing prerequisites"
                    install_dependencies || exit 1
                }

                build_kernel || exit 1
                run_tests || true

                print_header "Setup Complete!"
                printf "\n"
                printf "${GREEN}Next steps:${NC}\n"
                printf "  cd ${PROJECT_DIR}\n"
                printf "  make emulate          # Run kernel\n"
                printf "  make debug            # Debug with GDB\n"
                printf "  make help             # See all targets\n"
                printf "\n"
                ;;
            6)
                cat << EOF

${BLUE}${PROJECT_NAME} - Information${NC}

Project: $PROJECT_NAME
Location: ${PROJECT_DIR}

Key Files:
  Makefile              Build system (20+ targets)
  DEVELOPMENT.md        Development guide
  DEBUGGING.md          GDB debugging guide
  TESTING_GUIDE.md      Testing documentation
  FEATURES.md           Planned features
  CHANGELOG.md          Version history

Quick Commands:
  make help             Show all make targets
  make build-x86_64     Build kernel
  make emulate          Run in QEMU
  make debug            Debug with GDB
  make test             Run all tests
  make clean            Clean build artifacts

Documentation:
  See README.md for complete documentation
  See DEVELOPMENT.md for contribution guidelines

Support:
  Check GitHub Issues: https://github.com/...
  See documentation files for more help

EOF
                ;;
            0)
                printf "\n${YELLOW}Goodbye!${NC}\n\n"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
    done
}

# ============================================================================
# RUN MAIN
# ============================================================================

main "$@"
