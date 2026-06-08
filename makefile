################################################################################
# @file Makefile
# @brief Build system for 64-bit OS kernel
#
# This Makefile provides targets for building, testing, debugging, and
# maintaining the OS kernel project.
#
# Quick Start:
#   make help           # Show all available targets
#   make build-x86_64   # Build kernel
#   make emulate        # Run in QEMU
#   make debug          # Debug with GDB
#   make test           # Run tests
#   make clean          # Clean build artifacts
#
# Configuration:
#   VERBOSE=1           # Verbose compiler output
#   DEBUG=1             # Include debug symbols
#
# See DEVELOPMENT_WORKFLOW.md for detailed documentation
################################################################################

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

## Project metadata
PROJECT_NAME = OS Kernel 64-bit
PROJECT_VERSION = 0.1.0
PROJECT_AUTHOR = Mo

## Architecture
ARCH = x86_64

## Source directories
SRC_DIR = src
SRC_IMPL_DIR = $(SRC_DIR)/impl
SRC_INTF_DIR = $(SRC_DIR)/intf
BOOT_DIR = $(SRC_IMPL_DIR)/$(ARCH)/boot

## Output directories
BUILD_DIR = build
DIST_DIR = dist/$(ARCH)

## Compiler and tools
NASM = nasm
CC = gcc
LD = ld
AR = ar
GRUB_MKRESCUE = grub-mkrescue

## Compiler flags with strict checking
CFLAGS = \
	-Wall \
	-Wextra \
	-Werror \
	-fno-exceptions \
	-fno-rtti \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-O2 \
	-g

## Assembler flags
ASMFLAGS = -f elf64

## Linker flags
LDFLAGS = -nostdlib -z max-page-size=0x1000

## Additional flags for debugging
DEBUG ?= 0
ifeq ($(DEBUG), 1)
    CFLAGS += -g3 -O0
    LDFLAGS += -g
endif

## Verbose mode
VERBOSE ?= 0
ifeq ($(VERBOSE), 1)
    VERB =
else
    VERB = @
endif

# ============================================================================
# FILE DEFINITIONS
# ============================================================================

## Boot loader source files
BOOT_SRC = $(BOOT_DIR)/header.asm
BOOT_MAIN = $(BOOT_DIR)/main.asm
BOOT_MAIN64 = $(BOOT_DIR)/main64.asm

## Kernel source files
KERNEL_SRC = \
	$(SRC_IMPL_DIR)/kernel/main.c \
	$(SRC_IMPL_DIR)/$(ARCH)/print.c

## Object files
BOOT_OBJ = $(BUILD_DIR)/boot.o
BOOT_MAIN_OBJ = $(BUILD_DIR)/main.o
BOOT_MAIN64_OBJ = $(BUILD_DIR)/main64.o
KERNEL_OBJ = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(KERNEL_SRC))

## All object files
ALL_OBJ = $(BOOT_OBJ) $(BOOT_MAIN_OBJ) $(BOOT_MAIN64_OBJ) $(KERNEL_OBJ)

## Output kernel binary
KERNEL_BINARY = $(DIST_DIR)/kernel.bin

## ISO image
KERNEL_ISO = $(DIST_DIR)/kernel.iso

## Linker script
LINKER_SCRIPT = linker.ld

# ============================================================================
# PHONY TARGETS (Don't create files with these names)
# ============================================================================

.PHONY: \
	help build-x86_64 build clean distclean \
	emulate run debug \
	test test-unit test-integration \
	docs install-deps show-config \
	format lint

# ============================================================================
# DEFAULT TARGET
# ============================================================================

.DEFAULT_GOAL := help

# ============================================================================
# HELP TARGET
# ============================================================================

##
## @brief Display all available make targets with descriptions
##
## Shows a formatted help message listing all available targets and their
## purposes. Useful for new developers getting familiar with the project.
##
help:
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════════════════════╗"
	@echo "║                     $(PROJECT_NAME) v$(PROJECT_VERSION)                        ║"
	@echo "║                           Build System Help                                ║"
	@echo "╚════════════════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Build Targets:"
	@echo "  make build-x86_64       Build 64-bit kernel image (default target)"
	@echo "  make build              Alias for build-x86_64"
	@echo "  make clean              Remove build artifacts (*.o files)"
	@echo "  make distclean          Remove ALL build output (build/ and dist/)"
	@echo ""
	@echo "Execution Targets:"
	@echo "  make emulate            Run kernel in QEMU emulator"
	@echo "  make run                Alias for emulate"
	@echo "  make debug              Run kernel in QEMU with GDB debugger"
	@echo ""
	@echo "Testing Targets:"
	@echo "  make test               Run all tests (unit + integration)"
	@echo "  make test-unit          Run unit tests only"
	@echo "  make test-integration   Run integration tests with QEMU"
	@echo ""
	@echo "Development Targets:"
	@echo "  make docs               Generate Doxygen documentation"
	@echo "  make install-deps       Install required dependencies"
	@echo "  make show-config        Display build configuration"
	@echo "  make format             Format source code (clang-format)"
	@echo "  make lint               Run static analysis (clang-tidy)"
	@echo ""
	@echo "Options:"
	@echo "  VERBOSE=1               Show all compiler commands"
	@echo "  DEBUG=1                 Include debug symbols (-g3, -O0)"
	@echo "  ARCH=x86_64             Target architecture (default: x86_64)"
	@echo ""
	@echo "Examples:"
	@echo "  make build-x86_64                    # Build kernel"
	@echo "  make emulate                         # Run in QEMU"
	@echo "  make debug                           # Debug with GDB"
	@echo "  VERBOSE=1 make build-x86_64         # Build with verbose output"
	@echo "  DEBUG=1 make build-x86_64           # Build with debug symbols"
	@echo ""
	@echo "Quick Start:"
	@echo "  1. make install-deps    # Install dependencies"
	@echo "  2. make build-x86_64    # Compile kernel"
	@echo "  3. make emulate         # Test in QEMU"
	@echo ""

# ============================================================================
# CONFIGURATION TARGETS
# ============================================================================

##
## @brief Display build configuration
##
show-config:
	@echo ""
	@echo "Build Configuration:"
	@echo "  Architecture:    $(ARCH)"
	@echo "  Compiler:        $(CC)"
	@echo "  Assembler:       $(NASM)"
	@echo "  Debug Mode:      $(if $(filter 1,$(DEBUG)),Yes,No)"
	@echo "  Verbose:         $(if $(filter 1,$(VERBOSE)),Yes,No)"
	@echo "  CFLAGS:          $(CFLAGS)"
	@echo "  ASMFLAGS:        $(ASMFLAGS)"
	@echo "  LDFLAGS:         $(LDFLAGS)"
	@echo ""

##
## @brief Install required dependencies
##
## Installs all required build tools and libraries for compiling the kernel.
## Supports Ubuntu/Debian. Requires sudo.
##
install-deps:
	@echo "Installing dependencies..."
	@echo "This will require sudo access to install packages"
	sudo apt-get update
	sudo apt-get install -y \
		build-essential \
		nasm \
		qemu-system-x86 \
		xorriso \
		grub-common \
		gdb \
		gcc \
		binutils
	@echo "✓ Dependencies installed"

# ============================================================================
# BUILD TARGETS
# ============================================================================

## Create build directories
$(BUILD_DIR):
	@echo "Creating build directory..."
	$(VERB)mkdir -p $(BUILD_DIR)
	$(VERB)mkdir -p $(BUILD_DIR)/impl/$(ARCH)
	$(VERB)mkdir -p $(BUILD_DIR)/impl/$(ARCH)/boot
	$(VERB)mkdir -p $(BUILD_DIR)/impl/kernel

$(DIST_DIR):
	@echo "Creating distribution directory..."
	$(VERB)mkdir -p $(DIST_DIR)

##
## @brief Compile C source files to object files
##
## Pattern rule that compiles all C source files in src/ to object files
## in build/. Applies warning flags to catch potential issues.
##
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	@echo "Compiling: $<"
	$(VERB)$(CC) $(CFLAGS) -c $< -o $@

##
## @brief Assemble boot code to object files
##
## Compiles assembly files for the bootloader (header, main, main64).
## Each has specific flags for correct section placement.
##
$(BUILD_DIR)/boot.o: $(BOOT_SRC) | $(BUILD_DIR)
	@echo "Assembling: $<"
	$(VERB)$(NASM) $(ASMFLAGS) $< -o $@

$(BUILD_DIR)/main.o: $(BOOT_MAIN) | $(BUILD_DIR)
	@echo "Assembling: $<"
	$(VERB)$(NASM) $(ASMFLAGS) $< -o $@

$(BUILD_DIR)/main64.o: $(BOOT_MAIN64) | $(BUILD_DIR)
	@echo "Assembling: $<"
	$(VERB)$(NASM) $(ASMFLAGS) $< -o $@

##
## @brief Link object files into kernel binary
##
## Links all object files together using the linker script to create
## the final kernel executable. The linker script defines memory layout
## and section placement.
##
$(KERNEL_BINARY): $(ALL_OBJ) $(LINKER_SCRIPT) | $(DIST_DIR)
	@echo "Linking: $@"
	$(VERB)$(LD) $(LDFLAGS) -T $(LINKER_SCRIPT) $(ALL_OBJ) -o $@
	@echo "✓ Kernel binary created: $@"
	$(VERB)ls -lh $@

##
## @brief Create bootable ISO image
##
## Creates an ISO 9660 image with the kernel binary and GRUB bootloader.
## This image can be booted on x86_64 systems or in QEMU.
##
$(KERNEL_ISO): $(KERNEL_BINARY)
	@echo "Creating ISO image: $@"
	@mkdir -p $(DIST_DIR)/isofiles/boot/grub
	$(VERB)cp $(KERNEL_BINARY) $(DIST_DIR)/isofiles/boot/
	@echo "menuentry 'OS Kernel' { multiboot2 /boot/kernel.bin; }" > $(DIST_DIR)/isofiles/boot/grub/grub.cfg
	$(VERB)$(GRUB_MKRESCUE) -o $@ $(DIST_DIR)/isofiles/
	@echo "✓ ISO image created: $@"
	$(VERB)ls -lh $@

##
## @brief Build the complete kernel (default build target)
##
## Compiles and links all source files into a bootable ISO image.
## This is the main target used for daily development.
##
## Usage:
##   make build-x86_64
##   make build              (alias)
##
build-x86_64: $(KERNEL_ISO)
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════════════════════╗"
	@echo "║                    Build Complete                                         ║"
	@echo "║                                                                            ║"
	@echo "║  Image:  $(KERNEL_ISO)"
	@echo "║  Next:   make emulate     (run in QEMU)"
	@echo "║          make debug       (debug with GDB)"
	@echo "╚════════════════════════════════════════════════════════════════════════════╝"
	@echo ""

## Alias for build-x86_64
build: build-x86_64

# ============================================================================
# EXECUTION TARGETS
# ============================================================================

##
## @brief Run kernel in QEMU emulator
##
## Boots the kernel image in QEMU system emulator with these settings:
##   - 512MB RAM
##   - No GUI (serial output to console)
##   - Timeout of 5 seconds
##
## Usage:
##   make emulate
##   make run                (alias)
##
## To quit QEMU: Press Ctrl+A, then X
##
emulate: build-x86_64
	@echo "Starting QEMU..."
	@echo "To quit: Press Ctrl+A then X"
	@echo ""
	$(VERB)timeout 5 qemu-system-x86_64 \
		-cdrom $(KERNEL_ISO) \
		-m 512 \
		-serial stdio \
		-nographic \
		|| true

## Alias for emulate
run: emulate

##
## @brief Debug kernel with GDB and QEMU
##
## Launches QEMU in debug mode with GDB server on localhost:1234.
## Automatically attaches GDB and sets breakpoint at kernel entry.
##
## Usage:
##   make debug
##
## GDB Commands:
##   break kernel_main       Set breakpoint at kernel_main
##   continue                Resume execution
##   step                    Step one instruction
##   info registers          Show CPU registers
##   info locals             Show local variables
##   quit                    Exit GDB (kills QEMU)
##
debug: build-x86_64
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════════════════════╗"
	@echo "║                    Starting GDB Debugger                                  ║"
	@echo "║                                                                            ║"
	@echo "║  QEMU is running on localhost:1234                                        ║"
	@echo "║  Useful GDB commands:                                                      ║"
	@echo "║    break *0x100000      Set breakpoint at kernel entry point              ║"
	@echo "║    continue (c)         Resume execution                                  ║"
	@echo "║    step (s)             Step one instruction                              ║"
	@echo "║    info registers       Show CPU registers                                ║"
	@echo "║    x/10i $$pc           Show next 10 instructions                          ║"
	@echo "║    quit (q)             Exit debugger                                     ║"
	@echo "║                                                                            ║"
	@echo "╚════════════════════════════════════════════════════════════════════════════╝"
	@echo ""
	@qemu-system-x86_64 \
		-cdrom $(KERNEL_ISO) \
		-m 512 \
		-serial stdio \
		-nographic \
		-s -S &
	@sleep 1
	@gdb -ex "target remote localhost:1234" \
		-ex "break *0x100000" \
		-ex "continue" \
		$(KERNEL_BINARY) || true

# ============================================================================
# TESTING TARGETS
# ============================================================================

##
## @brief Run all tests
##
test:
	@$(MAKE) -f Makefile.testing test

##
## @brief Run unit tests only
##
test-unit:
	@$(MAKE) -f Makefile.testing test-unit

##
## @brief Run integration tests only
##
test-integration:
	@$(MAKE) -f Makefile.testing test-integration

# ============================================================================
# DOCUMENTATION TARGETS
# ============================================================================

##
## @brief Generate Doxygen documentation
##
## Creates HTML and LaTeX documentation from source code comments.
## Output is in docs/ directory.
##
docs:
	@echo "Generating documentation..."
	@if command -v doxygen >/dev/null 2>&1; then \
		doxygen Doxyfile; \
		echo "✓ Documentation generated in docs/html/"; \
	else \
		echo "ERROR: Doxygen not installed. Install with: apt-get install doxygen"; \
		exit 1; \
	fi

# ============================================================================
# CODE QUALITY TARGETS
# ============================================================================

##
## @brief Format source code with clang-format
##
format:
	@echo "Formatting source code..."
	@find $(SRC_DIR) -name "*.c" -o -name "*.h" | xargs clang-format -i
	@echo "✓ Code formatted"

##
## @brief Run static analysis with clang-tidy
##
lint:
	@echo "Running static analysis..."
	@find $(SRC_DIR) -name "*.c" | while read file; do \
		echo "Analyzing $$file..."; \
		clang-tidy "$$file" -- $(CFLAGS); \
	done

# ============================================================================
# CLEANUP TARGETS
# ============================================================================

##
## @brief Clean build artifacts (*.o files)
##
## Removes compiled object files but keeps the final kernel binary.
## Useful for forcing a full rebuild.
##
## Usage:
##   make clean
##
clean:
	@echo "Cleaning build artifacts..."
	$(VERB)rm -rf $(BUILD_DIR)/*.o
	$(VERB)rm -rf $(BUILD_DIR)/*/*.o
	$(VERB)rm -rf $(BUILD_DIR)/*/*/*.o
	@echo "✓ Build artifacts cleaned"

##
## @brief Deep clean - remove ALL build output
##
## Completely removes build/ and dist/ directories.
## Next build will be from scratch.
##
## Usage:
##   make distclean
##
distclean: clean
	@echo "Removing all build output..."
	$(VERB)rm -rf $(BUILD_DIR)
	$(VERB)rm -rf $(DIST_DIR)
	$(VERB)rm -rf docs/
	@echo "✓ All build output removed"

# ============================================================================
# DEBUGGING & DEVELOPMENT
# ============================================================================

##
## @brief Print all variable values (for debugging Makefile)
##
print-vars:
	@echo "ARCH           = $(ARCH)"
	@echo "SRC_DIR        = $(SRC_DIR)"
	@echo "BUILD_DIR      = $(BUILD_DIR)"
	@echo "DIST_DIR       = $(DIST_DIR)"
	@echo "CFLAGS         = $(CFLAGS)"
	@echo "ASMFLAGS       = $(ASMFLAGS)"
	@echo "LDFLAGS        = $(LDFLAGS)"
	@echo "KERNEL_BINARY  = $(KERNEL_BINARY)"
	@echo "KERNEL_ISO     = $(KERNEL_ISO)"
	@echo ""
	@echo "ALL_OBJ        = $(ALL_OBJ)"
