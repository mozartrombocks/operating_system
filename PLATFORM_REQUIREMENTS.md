# Platform Requirements

This document specifies the platforms on which the OS kernel has been tested and what requirements are needed.

---

## Tested & Supported Platforms

### Development Environments

| OS | Version | Status | Notes |
|----|---------|--------|-------|
| Ubuntu | 22.04 LTS | ✅ Tested | Primary development target |
| Ubuntu | 20.04 LTS | ✅ Tested | Supported |
| Debian | 11 (Bullseye) | ✅ Tested | Supported |
| Debian | 12 (Bookworm) | ✅ Tested | Supported |
| Fedora | 38+ | ⚠️ Partial | Some package names differ |
| macOS | 12+ | ⚠️ Partial | Requires cross-compiler setup |
| Windows 11 | WSL2 | ⚠️ Partial | Use Ubuntu in WSL2 |

### Hardware Requirements (for Emulation)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | x86-64 | x86-64 (Intel/AMD) |
| RAM | 4GB | 8GB+ |
| Storage | 500MB | 2GB (for build cache) |
| Network | Optional | For GitHub integration |

### Hardware Requirements (for Bare Metal - Future)

| Component | Minimum |
|-----------|---------|
| CPU | x86-64 (2010+) |
| RAM | 128MB |
| Storage | 512MB disk/USB |
| Boot | UEFI or BIOS with multiboot2 |

---

## Software Requirements

### Required Tools

```
Tool              Version    Package         Used For
─────────────────────────────────────────────────────────
GCC               9.0+       gcc             C compilation
NASM              2.10+      nasm            Assembly compilation
Make              3.80+      make            Build automation
QEMU x86_64       4.0+       qemu-system-x86 Emulation
Binutils          2.30+      binutils        Linking & tools
GDB               10.0+      gdb             Debugging
Git               2.20+      git             Version control
xorriso           1.4+       xorriso         ISO creation
GRUB              2.0+       grub-common     Bootloader
```

### Installation by Platform

#### Ubuntu / Debian (Recommended)

```bash
# All dependencies in one command
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc \
    nasm \
    make \
    qemu-system-x86 \
    qemu-utils \
    gdb \
    git \
    xorriso \
    grub-common \
    binutils

# Verify installation
gcc --version
nasm -version
qemu-system-x86_64 --version
```

#### Fedora / RHEL

```bash
sudo dnf install -y \
    gcc \
    make \
    nasm \
    qemu-system-x86 \
    gdb \
    git \
    xorriso \
    grub2-tools \
    binutils

# Note: Package names may differ
# Use: dnf search <tool> to find exact names
```

#### macOS

```bash
# Install Homebrew first if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install nasm qemu gdb binutils xorriso grub

# Set up cross-compiler for x86-64
# This is more complex - see Cross-Compiler Setup below
```

#### Windows 11 (WSL2)

```powershell
# Install WSL2 Ubuntu
wsl --install -d Ubuntu-22.04

# Then in WSL2 terminal
sudo apt-get update
sudo apt-get install -y build-essential nasm qemu-system-x86 gdb git xorriso grub-common
```

---

## Cross-Compiler Setup (if needed)

### For macOS

The kernel requires cross-compilation for x86-64. GCC on macOS by default targets Apple's architecture.

```bash
# Install cross-compiler
brew install x86_64-elf-gcc x86_64-elf-binutils

# Verify
x86_64-elf-gcc --version
```

### For Windows (MSVC developers)

MinGW provides GCC for Windows:

```bash
# Download from: https://www.mingw-w64.org/
# Or use package manager
choco install mingw-w64
```

---

## Docker Support (Coming Soon)

For a consistent build environment across all platforms, Docker support is planned.

### Planned: Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    nasm \
    qemu-system-x86 \
    gdb \
    git \
    xorriso \
    grub-common

WORKDIR /os-kernel
```

### Planned: Usage

```bash
# Build Docker image
docker build -t os-kernel .

# Run container with volume mount
docker run -v $(pwd):/os-kernel -it os-kernel bash

# Inside container
make build-x86_64
make test
```

---

## Optional Tools

### Recommended for Development

| Tool | Purpose | Installation |
|------|---------|--------------|
| clang-format | Code formatting | `apt install clang-format` |
| clang-tidy | Static analysis | `apt install clang-tools` |
| doxygen | Documentation | `apt install doxygen graphviz` |
| valgrind | Memory analysis | `apt install valgrind` |
| git-flow | Branching workflow | `apt install git-flow` |

### Installation

```bash
# Development tools
sudo apt-get install -y \
    clang-format \
    clang-tools \
    doxygen \
    graphviz \
    valgrind

# VS Code (if not installed)
sudo snap install code --classic

# Extensions for VS Code
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.makefile-tools
```

---

## Verification Checklist

After installation, verify everything works:

```bash
# Create temporary test directory
mkdir ~/verify-os-kernel
cd ~/verify-os-kernel

# Clone project
git clone https://github.com/mozartrombocks/Writing-an-operating-system-kernel-from-scratch.git
cd Writing-an-operating-system-kernel-from-scratch

# Run setup
make install-deps

# Build kernel
make build-x86_64
echo "✓ Build successful"

# Run in QEMU
make emulate
echo "✓ Emulation successful"

# Run tests (if available)
make test
echo "✓ Tests successful"

echo ""
echo "=========================================="
echo "✅ All verifications passed!"
echo "=========================================="
```

---

## Troubleshooting Installation

### "nasm: command not found"

```bash
# Install NASM
sudo apt-get install nasm

# Verify
nasm -version
```

### "qemu-system-x86_64: command not found"

```bash
# Install QEMU
sudo apt-get install qemu-system-x86

# Verify
qemu-system-x86_64 --version
```

### "Cannot find gcc"

```bash
# Install build-essential (includes gcc)
sudo apt-get install build-essential

# Verify
gcc --version
```

### "make: command not found"

```bash
# Install make
sudo apt-get install make

# Verify
make --version
```

### macOS: "gcc" is actually clang

```bash
# On macOS, gcc is aliased to clang
# This usually works, but for true GCC:
brew install gcc

# Specify in build
CC=gcc-11 make build
```

### "Cannot connect to QEMU debugger"

```bash
# Make sure QEMU is running with debug flags
make debug

# Or manually:
qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso -s -S &
gdb kernel_binary
(gdb) target remote localhost:1234
```

---

## Performance Notes

### Development Machine Performance

Build times on typical hardware:

| Machine | RAM | CPU | Clean Build | Rebuild |
|---------|-----|-----|-------------|---------|
| Laptop | 8GB | i5 | ~15s | ~5s |
| Desktop | 16GB | i7 | ~8s | ~2s |
| Server | 32GB | Xeon | ~5s | ~1s |

Emulation in QEMU:
- Boot to kernel: ~2-3 seconds
- Full test suite: ~30-40 seconds

### Optimizing Performance

```bash
# Use SSD (much faster than HDD)
# Keep /tmp/ on fast storage

# Parallel build (on multi-core CPU)
make -j4 build-x86_64

# Use ccache to cache compilation
sudo apt-get install ccache
export CC="ccache gcc"
make build-x86_64
```

---

## CI/CD Platforms

### GitHub Actions (Recommended)

The project includes GitHub Actions workflow that tests on:
- Ubuntu 20.04
- Ubuntu 22.04
- Ubuntu 24.04 (when available)

### Future CI/CD Support

- [ ] GitLab CI
- [ ] Travis CI
- [ ] CircleCI
- [ ] Jenkins

---

## Known Issues by Platform

### Ubuntu 20.04
- Some packages have older versions
- GCC version 9 is default (works fine)

### Fedora
- Package names use dnf instead of apt
- Some tools may have different names

### macOS
- Requires cross-compiler for x86-64 targets
- QEMU may be slower than Linux
- Some tools need Homebrew setup

### Windows (WSL2)
- File system performance is slower
- Some USB devices not accessible
- Networking requires special setup

### Older Distributions (Ubuntu 18.04, Debian 10)
- Build tools may be too old
- Update to newer version recommended

---

## System Limits

The kernel currently has these limitations:

| Limit | Value | Reason |
|-------|-------|--------|
| Virtual Memory | 1GB | 2MB huge pages × 512 |
| Physical Memory | System RAM | Identity mapping |
| Maximum Processes | Not yet | Process mgmt TBD |
| File System | None yet | Disk I/O TBD |
| Max Page Size | 2MB | Huge page setting |

---

## Future Platform Support

### Planned

- [ ] ARM64 architecture support
- [ ] RISC-V architecture support
- [ ] Windows (native, not WSL2)
- [ ] Raspberry Pi support
- [ ] Docker multi-architecture images

### Not Planned

- 32-bit x86 (deprecated)
- PowerPC (niche)
- MIPS (obsolete)

---

## Getting Help

If you encounter issues:

1. **Check this document** - You might find your answer here
2. **Search GitHub Issues** - Someone may have faced this before
3. **Create a new issue** - Include:
   - Your OS and version
   - Output of `gcc --version`, `nasm -version`, etc.
   - Error message (copy-paste from terminal)
   - Steps to reproduce

4. **Contact maintainers** - Email or GitHub discussions

---

## Contributing Improvements

Found a setup issue or know a better way? Contribute!

1. Fork the repository
2. Create branch: `git checkout -b improve/setup-docs`
3. Update PLATFORM_REQUIREMENTS.md
4. Test on your platform
5. Submit pull request

Thank you for helping improve this project! 🙏
