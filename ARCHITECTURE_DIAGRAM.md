# OS Kernel Architecture Diagram

## System Boot Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      BOOTLOADER (GRUB)                          │
│                  - Loads multiboot2 header                      │
│                  - Hands control to main.asm                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               src/impl/x86_64/boot/main.asm                      │
│                    (32-bit Boot Stage)                          │
│  • Verify multiboot signature                                   │
│  • Check CPUID support                                          │
│  • Verify long mode (64-bit) support                            │
│  • Setup 4-level page tables (L4→L3→L2)                         │
│  • Enable PAE (Physical Address Extension)                      │
│  • Enable long mode via MSR                                     │
│  • Enable paging via CR0                                        │
│  • Load 64-bit GDT                                              │
│  • Jump to long_mode_start                                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│            src/impl/x86_64/boot/main64.asm                       │
│                   (64-bit Boot Stage)                           │
│  • Zero segment registers                                       │
│  • Call kernel_main()                                           │
│  • Halt CPU                                                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           src/impl/kernel/main.c                                 │
│                   (Kernel Main Logic)                           │
│  • Initialize video buffer (0xb8000)                            │
│  • Set text color to green                                      │
│  • Print welcome message                                        │
└─────────────────────────────────────────────────────────────────┘
```

## Memory Layout

```
Virtual Memory (64-bit):
┌──────────────────────────────┐
│   Kernel Code & Data         │  High addresses
│   (mapped by main.asm)       │
├──────────────────────────────┤
│   Stack (4 pages, 16KB)      │
│   (grows downward)           │
├──────────────────────────────┤
│   Page Tables (L4,L3,L2)     │
│   (4KB each)                 │
├──────────────────────────────┤
│   Video Buffer               │  0xb8000 (text mode)
│   (80 cols × 25 rows)        │
└──────────────────────────────┘  Low addresses

Paging Structure:
CR3 → Page Table L4 (PML4E)
       ↓
    Page Table L3 (PDPE)
       ↓
    Page Table L2 (PDE - Huge Pages)
       ↓
    2MB Pages × 512 = 1GB total
```

## Module Dependency Graph

```
    BOOTLOADER (GRUB)
           │
           ├─→ main.asm (32-bit boot)
           │        │
           │        ├─→ header.asm (multiboot2 header)
           │        │
           │        └─→ main64.asm (64-bit boot)
           │                 │
           │                 └─→ main.c (kernel initialization)
           │                      │
           │                      └─→ print.h / print.c (output)
           │
           └─→ linker.ld (memory layout)
```

## Key Components

### 1. Bootloader Stage (main.asm)
- **Purpose**: Transition from 32-bit to 64-bit mode
- **Inputs**: Multiboot info from GRUB (EAX = signature, EBX = pointer)
- **Outputs**: Sets up paging, GDT, enters 64-bit long mode
- **Key Operations**:
  - Multiboot validation
  - CPU capability checks
  - Page table setup
  - Control register configuration

### 2. Long Mode Initialization (main64.asm)
- **Purpose**: Initialize 64-bit environment
- **Inputs**: Clean state from 32-bit bootloader
- **Outputs**: Calls kernel_main()
- **Key Operations**:
  - Segment register zeroing
  - Stack frame setup
  - Kernel entry point invocation

### 3. Kernel Core (main.c)
- **Purpose**: Main kernel logic
- **Inputs**: None (system already initialized)
- **Outputs**: Text printed to video buffer
- **Key Operations**:
  - Display initialization
  - Color configuration
  - User-facing messages

### 4. Print Subsystem (print.h / print.c)
- **Purpose**: Text mode video output
- **Inputs**: Characters and color codes
- **Outputs**: Video buffer updates (0xb8000)
- **Components**:
  - `print_char()` - Write single character
  - `print_str()` - Write string
  - `print_clear()` - Clear screen
  - `print_set_color()` - Set foreground/background color

## Data Structures

### Color Encoding
```c
uint8_t color = foreground | (background << 4)
// Foreground: 0-15 (16 colors)
// Background: 0-7  (8 colors)
```

### Video Buffer Entry
```c
struct Char {
    uint8_t character;  // ASCII character
    uint8_t color;      // High 4-bits: background, Low 4-bits: foreground
}
// Located at: 0xb8000 (physical address)
// Size: 2 bytes per character × 80 cols × 25 rows = 4000 bytes
```

## Next Steps for Enhancement

1. **Interrupt handling** - IDT setup for CPU exceptions
2. **Memory management** - Heap allocator, memory protection
3. **Filesystem** - Disk I/O, file system drivers
4. **Process management** - Task switching, multitasking
5. **System calls** - User mode and kernel mode boundary
