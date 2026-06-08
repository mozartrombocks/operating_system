# Writing a 64-bit Operating System Kernel from Scratch

A bare-metal 64-bit OS kernel implementation with bootloader, memory management, and interrupt handling.

## Prerequisites

Install the following dependencies before building:

- **nasm** - Assembler for x86-64 assembly code
- **qemu** - x86_64 system emulator for testing
- **xorriso** - ISO 9660 filesystem creation tool
- **grub-common** - Bootloader support
- **x86_64-elf-gcc** - Cross-compiler for x86-64 ELF targets
- **x86_64-elf-ld** - Cross-linker for x86-64

### Installation (Ubuntu/Debian)

```bash
sudo apt-get install nasm qemu-system-x86 xorriso grub-common
# For cross-compiler tools, see OSDev Wiki resources below
```

## Building

```bash
make build-x86_64
```

This compiles all assembly and C source files, links them with the cross-compiler, and generates a bootable ISO image.

## Emulation

To test the kernel in QEMU:

```bash
qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso
```

### Useful QEMU Options

- `-m 512` - Allocate 512MB RAM
- `-smp 2` - Emulate 2 CPU cores
- `-gdb tcp::1234` - Enable GDB debugging
- `-serial stdio` - Redirect serial output to terminal

## Project Structure

```
├── boot/          - Bootloader (GRUB multiboot2)
├── kernel/        - Core kernel code
│   ├── arch/      - Architecture-specific code (x86-64)
│   ├── mm/        - Memory management
│   ├── interrupt/ - Interrupt handling
│   └── io/        - I/O operations
├── libc/          - Standard C library
├── Makefile       - Build configuration
└── linker.ld      - Linker script for kernel layout
```

## Features

- [X] 64-bit protected mode
- [X] GRUB multiboot2 bootloader
- [X] Paging and virtual memory (if implemented)
- [X] Interrupt/exception handling
- [X] Basic kernel console output

## Contributing

Contributions welcome! Please:

1. Follow existing code style
2. Test changes in QEMU
3. Document new features
4. Submit pull requests with clear descriptions

## References

- [OSDev Wiki](https://wiki.osdev.org/) - Comprehensive OS development guide
- [Intel x86-64 Manual](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-1-manual.pdf)
- [GNU ELF Linker Documentation](https://sourceware.org/binutils/docs/ld/)
- [Multiboot2 Specification](https://www.gnu.org/software/grub/manual/multiboot2/)

## Author

Mohammed (Mo) Rahman; shadman9702@gmail.com
