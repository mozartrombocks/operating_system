# Development Workflow Guide

This guide explains the improved development workflow for your OS kernel project, including build system improvements, version control setup, and debugging tools.

---

## 1. .gitignore Configuration

### Purpose

The `.gitignore` file prevents build artifacts, IDE artifacts, and temporary files from being committed to git. This keeps the repository clean and focused on source code.

### What's Ignored

**Build Artifacts:**
- Object files (*.o, *.obj)
- Library files (*.a, *.lib, *.so)
- Build directories (build/, dist/, bin/, obj/)

**Output Files:**
- Kernel images (*.iso, *.img, *.bin, *.elf)
- Compiled executables

**IDE Artifacts:**
- VS Code (.vscode/)
- Visual Studio (.vs/)
- CLion / IntelliJ (.idea/)
- Vim (.swp, .swo)
- Emacs (#*#, .*#)

**Temporary Files:**
- Logs (*.log)
- Backups (*.bak, *.backup)
- QEMU output files

**System Files:**
- macOS (.DS_Store)
- Windows (Thumbs.db)
- Linux (.cache)

**Test Artifacts:**
- Test executables (test_print, test_memory, etc.)
- Test results

**Documentation:**
- Generated Doxygen docs (docs/, html/, latex/)

### How It Works

When you commit files, git checks `.gitignore` patterns:

```bash
# These WILL be tracked:
src/main.c
src/impl/print.c
Makefile
.gitignore

# These WILL NOT be tracked:
build/kernel.o
dist/kernel.iso
.vscode/settings.json
*.log
test_print
```

### Adding New Patterns

If you want to exclude more files:

```bash
# Edit .gitignore
nano .gitignore

# Add new pattern (one per line)
*.myextension
path/to/temp/

# Commit changes
git add .gitignore
git commit -m "Update .gitignore"
```

### Checking What Will Be Tracked

```bash
# Show all files git would track (respecting .gitignore)
git add -n .

# Show status of all files
git status

# Show files ignored by .gitignore
git status --ignored
```

---

## 2. Improved Makefile

### Key Targets

#### build-x86_64 / build

Compiles the kernel from source code to bootable ISO image.

```bash
make build-x86_64          # Build kernel
make build                 # Alias for build-x86_64
VERBOSE=1 make build       # Show compiler commands
DEBUG=1 make build         # Include debug symbols
```

**What it does:**
1. Compiles C source files
2. Assembles bootloader code
3. Links everything together
4. Creates ISO image

**Output:**
- `dist/x86_64/kernel.iso` - Bootable image for QEMU or real hardware

#### clean

Removes intermediate build artifacts (object files) but keeps the final binary.

```bash
make clean
```

**Useful for:**
- Forcing a rebuild of specific files
- Cleaning up after a build
- Freeing disk space while keeping binaries

**Output:**
- Removes `build/*.o` files

#### distclean

Complete cleanup - removes build/ and dist/ directories.

```bash
make distclean
```

**Useful for:**
- Starting completely fresh
- Before committing to git
- Troubleshooting build issues

**Output:**
- Removes `build/` directory
- Removes `dist/` directory
- Removes `docs/` directory

#### help

Displays all available targets and options.

```bash
make help
```

**Shows:**
- All available targets
- Quick descriptions
- Usage examples
- Configuration options

#### debug

Runs the kernel in QEMU with GDB debugger attached.

```bash
make debug
```

**What it does:**
1. Builds the kernel
2. Starts QEMU in debug mode
3. Automatically launches GDB
4. Sets breakpoint at kernel entry
5. Displays helpful debugging commands

**GDB Commands:**
```
continue (c)                Resume execution
step (s)                    Execute one instruction
break *0x100000             Set breakpoint at address
info registers              Show CPU registers
x/10i $pc                   Show 10 instructions at program counter
backtrace (bt)              Show call stack
quit (q)                    Exit debugger
```

#### emulate / run

Boots the kernel in QEMU emulator.

```bash
make emulate               # Run kernel
make run                   # Alias
```

**Settings:**
- 512MB RAM
- Serial output to console
- No GUI
- 5 second timeout

**Output:**
- Kernel welcome message
- Any kernel output to serial port

#### test

Runs all tests (requires test framework).

```bash
make test
make test-unit
make test-integration
```

#### install-deps

Installs required build tools.

```bash
make install-deps
```

**Installs:**
- build-essential
- nasm (assembler)
- qemu-system-x86 (emulator)
- xorriso (ISO creation)
- grub-common (bootloader)
- gdb (debugger)
- gcc, binutils

### Build Flags

#### Warning Flags

The Makefile includes strict compiler warnings:

```makefile
CFLAGS = -Wall -Wextra -Werror ...
```

**-Wall:**
- Enables all common warnings
- Catches undefined variables
- Detects missing return statements
- Warns about unused variables

**-Wextra:**
- Additional warnings beyond -Wall
- Missing field initializers
- Suspicious type conversions
- Implicit function declarations

**-Werror:**
- Treats all warnings as errors
- Forces you to fix issues
- Prevents bad code from compiling

**Example - Before (no warnings):**
```c
int calculate(int x) {
    int result;  // Uninitialized - WARNING!
    // Missing return - WARNING!
}
```

**After (with -Wall -Wextra):**
```
error: variable 'result' set but not used [-Werror=unused-variable]
error: control reaches end of non-void function [-Werror=return-type]
```

#### Optimization Flags

```makefile
CFLAGS = ... -O2 ...
```

**-O2:**
- Enables optimizations
- Inline small functions
- Loop unrolling
- Dead code elimination
- Moderate compile time (good for development)

#### Architecture Flags

```makefile
CFLAGS = ... -ffreestanding -fno-builtin -nostdlib ...
```

**-ffreestanding:**
- Assume standard library may not exist
- Required for kernel development
- `main()` doesn't need to be program entry

**-fno-builtin:**
- Disable built-in function optimizations
- Ensures actual functions are called
- Important for custom memory functions

**-nostdlib:**
- Don't link against standard C library
- Kernel is fully self-contained
- No external dependencies

#### Debug Flags

Enabled with `DEBUG=1`:

```bash
DEBUG=1 make build-x86_64
```

Adds:
- `-g3` - Full debug information
- `-O0` - No optimization (easier to debug)

### Configuration Options

```bash
# Verbose output
VERBOSE=1 make build-x86_64

# Debug build
DEBUG=1 make build-x86_64

# Both
VERBOSE=1 DEBUG=1 make build-x86_64

# Show configuration
make show-config
```

### Example Workflow

```bash
# 1. Check available targets
make help

# 2. Install dependencies (first time only)
make install-deps

# 3. Build kernel
make build-x86_64

# 4. Run in emulator
make emulate

# 5. Debug with GDB
make debug

# 6. Run tests
make test

# 7. Clean up
make clean

# 8. Complete rebuild
make distclean
make build-x86_64
```

---

## 3. Git Workflow

### Initial Setup

```bash
# Initialize git repository (first time only)
cd /path/to/project
git init

# Configure user info
git config user.name "Your Name"
git config user.email "your@email.com"

# Add all files
git add .

# Commit initial version
git commit -m "Initial commit: OS kernel skeleton"
```

### Daily Workflow

```bash
# 1. Check what files changed
git status

# 2. See differences
git diff src/impl/kernel/main.c

# 3. Stage changes for commit
git add src/

# 4. Commit with descriptive message
git commit -m "Add memory allocator implementation

- Implemented malloc/free for kernel heap
- Supports up to 64MB allocation
- Includes fragmentation tracking
- Fixes #42"

# 5. Push to remote (if using GitHub)
git push origin main

# 6. Create feature branch
git checkout -b feature/interrupt-handling
# ... make changes ...
git commit -m "Implement interrupt handling"
git push origin feature/interrupt-handling
# ... create pull request on GitHub ...
```

### Why .gitignore Matters

**Without .gitignore:**
```bash
$ git status
On branch main
Untracked files:
  build/
  dist/
  .vscode/
  *.log
  test_print
  # ... 1000+ build artifacts ...
```

**With .gitignore:**
```bash
$ git status
On branch main
nothing to commit, working tree clean
# Clean and focused!
```

---

## 4. Debugging Workflow

### Using the Debug Target

```bash
# Start debugging
make debug

# This automatically:
# 1. Builds the kernel
# 2. Starts QEMU in debug mode
# 3. Launches GDB
# 4. Sets breakpoint at entry
```

### Common Debug Scenarios

#### Debug Boot Sequence

```gdb
(gdb) break *0x100000              # Breakpoint at entry
(gdb) continue                      # Run until breakpoint
(gdb) step                          # Step through boot code
(gdb) info registers               # Show CPU registers
(gdb) x/10i $pc                    # Show instructions
```

#### Debug Kernel Main

```gdb
(gdb) break kernel_main            # Set breakpoint by function name
(gdb) continue                      # Run until function
(gdb) step                          # Step into function
(gdb) print result                  # Print variable value
(gdb) info locals                   # Show local variables
```

#### Watch Variable

```gdb
(gdb) watch color                   # Break when color changes
(gdb) continue                      # Run
(gdb) # Automatically breaks when color is written
```

#### Show Memory

```gdb
(gdb) x/100bx 0xb8000             # Show 100 bytes from video buffer
(gdb) x/10i 0x100000              # Show 10 instructions from entry
```

---

## 5. Build Flags Comparison

### Minimal Build (Minimal checking)
```bash
gcc -c main.c -o main.o
# No warnings, may compile broken code!
```

### Standard Build (Your project)
```bash
gcc -Wall -Wextra -Werror -O2 -ffreestanding -fno-builtin main.c
# Catches bugs at compile time
# Optimized for performance
# Fails on any warning
```

### Debug Build
```bash
DEBUG=1 make build
# gcc -Wall -Wextra -Werror -g3 -O0 -ffreestanding ...
# Full debug info, no optimization
# Easier to debug, slower execution
```

---

## 6. Best Practices

### Commit Messages

✅ **Good:**
```
Add interrupt handler for keyboard input

- Implement PS/2 keyboard driver
- Parse scan codes to ASCII
- Queue keypresses in buffer
- Fixes #123
```

❌ **Bad:**
```
fixed stuff
update
changes
```

### Build Hygiene

✅ **DO:**
- Commit `.gitignore` to repository
- Clean before major rebuilds: `make distclean`
- Use version control for all source files
- Never commit build artifacts

❌ **DON'T:**
- Commit *.o files, *.iso, or build/ directory
- Use `git add *` (might add artifacts)
- Delete .gitignore from repository

### Makefile Usage

✅ **DO:**
- Use `make help` to find available targets
- Use `DEBUG=1` when debugging
- Use `make clean` after long sessions
- Use `VERBOSE=1` when troubleshooting

❌ **DON'T:**
- Manually compile with gcc (use make)
- Ignore make errors
- Modify Makefile without testing
- Commit temporary Makefile changes

### Debugging

✅ **DO:**
- Use `make debug` for GDB debugging
- Set breakpoints at interesting points
- Print variables with `print` command
- Use `info registers` to inspect CPU state

❌ **DON'T:**
- Add debug printfs and recompile
- Ignore compiler warnings
- Debug without symbols (`make distclean` removes them!)
- Leave breakpoints in after debugging

---

## 7. Troubleshooting

### Build Fails: "Command not found: nasm"

```bash
# Install missing dependency
sudo apt-get install nasm

# Or install all at once
make install-deps
```

### QEMU Won't Run

```bash
# Check if QEMU is installed
which qemu-system-x86_64

# If not:
sudo apt-get install qemu-system-x86

# Check if ISO was created
ls -lh dist/x86_64/kernel.iso
```

### GDB Won't Connect

```bash
# Make sure you used 'make debug' not 'make emulate'
make debug

# Or manually:
qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso -s -S &
gdb kernel binary name
(gdb) target remote localhost:1234
```

### Files Being Tracked That Shouldn't Be

```bash
# Remove from git but keep locally
git rm --cached build/
git rm --cached dist/

# Or if accidentally committed
git rm -r --cached .
git add .
git commit -m "Remove build artifacts from git"
```

---

## 8. Quick Reference

```bash
make help                      # Show all targets
make build-x86_64             # Build kernel
make clean                    # Remove object files
make distclean                # Remove all build output
make emulate                  # Run in QEMU
make debug                    # Debug with GDB
make test                     # Run tests
make install-deps             # Install dependencies
make show-config              # Show build settings

# Options
VERBOSE=1 make build          # Verbose output
DEBUG=1 make build            # Debug build

# Git
git add .
git commit -m "message"
git push
git status
```

---

## Conclusion

This workflow provides:
- **Clean repository** via `.gitignore`
- **Professional build system** with Makefile
- **Strict compilation** with warning flags
- **Easy debugging** with GDB integration
- **Clear development process** with git

Your project is now set up for professional development! 🚀

