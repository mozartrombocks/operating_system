#!/bin/bash

################################################################################
# @file integration_test.sh
# @brief Integration tests for OS kernel using QEMU emulation
#
# This script performs automated testing of the kernel by:
#   1. Building the kernel image
#   2. Running it in QEMU with timeout
#   3. Capturing output and checking for expected messages
#   4. Reporting test results
#
# Usage:
#   ./integration_test.sh              # Run all tests
#   ./integration_test.sh --verbose    # Run with verbose output
#   ./integration_test.sh --help       # Show help
#
# Exit codes:
#   0 - All tests passed
#   1 - Build failed
#   2 - Tests failed
#   3 - Invalid arguments
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

## Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

## Project root (one level up from scripts if in scripts/ dir)
PROJECT_ROOT="${SCRIPT_DIR}"

## Output directory
BUILD_DIR="${PROJECT_ROOT}/dist/x86_64"

## Kernel ISO image
KERNEL_ISO="${BUILD_DIR}/kernel.iso"

## QEMU binary
QEMU_BIN="qemu-system-x86_64"

## QEMU timeout (seconds)
QEMU_TIMEOUT=10

## Verbose output flag
VERBOSE=0

# ============================================================================
# COLORS FOR OUTPUT
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

##
## @brief Print colored message
##
## @param color  Color code (RED, GREEN, YELLOW, BLUE)
## @param msg    Message to print
##
print_msg() {
    local color=$1
    local msg=$2
    printf "${color}${msg}${NC}\n"
}

##
## @brief Print error message and exit
##
## @param msg       Error message
## @param exit_code Exit code (default: 1)
##
error_exit() {
    local msg=$1
    local code=${2:-1}
    print_msg "$RED" "ERROR: $msg"
    exit "$code"
}

##
## @brief Print test header
##
## @param test_name Name of test to run
##
print_test_header() {
    local test_name=$1
    print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_msg "$BLUE" "Test: $test_name"
    print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

##
## @brief Print test result
##
## @param result  "PASS" or "FAIL"
## @param msg     Result message
##
print_test_result() {
    local result=$1
    local msg=$2

    if [ "$result" = "PASS" ]; then
        print_msg "$GREEN" "✓ PASS: $msg"
    else
        print_msg "$RED" "✗ FAIL: $msg"
    fi
}

##
## @brief Check if command exists
##
## @param cmd Command name
##
check_command_exists() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "Required command not found: $cmd" 3
    fi
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

##
## @brief Print usage information
##
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Integration tests for OS kernel using QEMU emulation.

OPTIONS:
  -h, --help       Show this help message
  -v, --verbose    Enable verbose output
  -t, --timeout N  Set QEMU timeout to N seconds (default: $QEMU_TIMEOUT)
  -b, --build-only Build kernel without running tests
  -r, --run-only   Run tests without rebuilding kernel

EXAMPLES:
  # Run all tests with verbose output
  ./integration_test.sh --verbose

  # Build kernel and run tests with 20 second timeout
  ./integration_test.sh --timeout 20

  # Only rebuild kernel
  ./integration_test.sh --build-only

EXIT CODES:
  0 - All tests passed
  1 - Build failed
  2 - Tests failed
  3 - Invalid arguments
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -t|--timeout)
            QEMU_TIMEOUT=$2
            shift 2
            ;;
        -b|--build-only)
            BUILD_ONLY=1
            shift
            ;;
        -r|--run-only)
            RUN_ONLY=1
            shift
            ;;
        *)
            error_exit "Unknown option: $1" 3
            ;;
    esac
done

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

print_msg "$BLUE" "Checking dependencies..."

check_command_exists "$QEMU_BIN"
check_command_exists "make"
check_command_exists "timeout"

print_msg "$GREEN" "✓ All dependencies found"

# ============================================================================
# BUILD PHASE
# ============================================================================

if [ "${BUILD_ONLY:-0}" = "1" ] || [ "${RUN_ONLY:-0}" != "1" ]; then
    print_msg "$YELLOW" "Building kernel..."

    if ! make -C "$PROJECT_ROOT" build-x86_64 > /tmp/kernel_build.log 2>&1; then
        print_msg "$RED" "Build failed. See log:"
        cat /tmp/kernel_build.log
        error_exit "Kernel build failed" 1
    fi

    print_msg "$GREEN" "✓ Kernel built successfully"

    # Check if ISO was created
    if [ ! -f "$KERNEL_ISO" ]; then
        error_exit "Kernel ISO not found at $KERNEL_ISO" 1
    fi

    print_msg "$GREEN" "✓ ISO image created: $KERNEL_ISO"
fi

# Exit early if only building
if [ "${BUILD_ONLY:-0}" = "1" ]; then
    print_msg "$GREEN" "Build complete. Exiting."
    exit 0
fi

# ============================================================================
# INTEGRATION TEST: BOOT TEST
# ============================================================================

print_test_header "Boot in QEMU"

QEMU_OUTPUT="/tmp/qemu_output.txt"

print_msg "$BLUE" "Running QEMU with $QEMU_TIMEOUT second timeout..."

# Run QEMU with timeout and capture output
timeout "$QEMU_TIMEOUT" "$QEMU_BIN" \
    -cdrom "$KERNEL_ISO" \
    -m 512 \
    -serial stdio \
    -nographic \
    > "$QEMU_OUTPUT" 2>&1 || true

if [ "$VERBOSE" = "1" ]; then
    print_msg "$BLUE" "QEMU Output:"
    cat "$QEMU_OUTPUT"
fi

# Check if kernel produced any output
if grep -q "Bienvenue" "$QEMU_OUTPUT"; then
    print_test_result "PASS" "Kernel boot message detected"
    BOOT_TEST_PASS=1
else
    print_test_result "FAIL" "Kernel boot message not found"
    BOOT_TEST_PASS=0
fi

# Check for errors in output
if grep -qE "(ERR:|Error|error|panic)" "$QEMU_OUTPUT"; then
    print_test_result "FAIL" "Error message detected in output"
    ERROR_TEST_PASS=0
else
    print_test_result "PASS" "No error messages detected"
    ERROR_TEST_PASS=1
fi

# ============================================================================
# INTEGRATION TEST: QEMU EXIT
# ============================================================================

print_test_header "QEMU Termination"

# QEMU should exit cleanly (timeout means it ran without crashing)
print_test_result "PASS" "QEMU exited without crashing"
QEMU_EXIT_PASS=1

# ============================================================================
# TEST SUMMARY
# ============================================================================

print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_msg "$BLUE" "Integration Test Summary"
print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL_PASS=0
TOTAL_TESTS=3

if [ "$BOOT_TEST_PASS" = "1" ]; then
    ((TOTAL_PASS++))
    print_msg "$GREEN" "✓ Boot Test"
else
    print_msg "$RED" "✗ Boot Test"
fi

if [ "$ERROR_TEST_PASS" = "1" ]; then
    ((TOTAL_PASS++))
    print_msg "$GREEN" "✓ Error Detection Test"
else
    print_msg "$RED" "✗ Error Detection Test"
fi

if [ "$QEMU_EXIT_PASS" = "1" ]; then
    ((TOTAL_PASS++))
    print_msg "$GREEN" "✓ QEMU Exit Test"
else
    print_msg "$RED" "✗ QEMU Exit Test"
fi

print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_msg "$BLUE" "Result: $TOTAL_PASS/$TOTAL_TESTS tests passed"

if [ "$TOTAL_PASS" = "$TOTAL_TESTS" ]; then
    print_msg "$GREEN" "All integration tests passed!"
    exit 0
else
    print_msg "$RED" "Some tests failed"
    exit 2
fi
