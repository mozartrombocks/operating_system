# Features & Roadmap

## Current Features (v0.1.0)

### Core Bootloader
- ✅ Multiboot2 compliance
- ✅ CPU capability detection (CPUID)
- ✅ 64-bit mode initialization
- ✅ 4-level paging setup
- ✅ GDT configuration

### Kernel
- ✅ 64-bit protected mode
- ✅ VGA text mode output (80x25)
- ✅ Color support (16 colors)
- ✅ Screen control (clear, scroll, cursor)
- ✅ String printing

### Development
- ✅ Professional build system
- ✅ Unit testing framework
- ✅ Integration testing with QEMU
- ✅ GitHub Actions CI/CD
- ✅ Comprehensive documentation
- ✅ Git workflow setup

---

## Planned Features

### Phase 1: I/O & Debugging (v0.2.0)
**Target: Q3 2026**

#### Serial Port Debugging
- [ ] Serial port driver (COM1)
- [ ] Send/receive functions
- [ ] Debug logging macros
- [ ] Kernel log buffer
- [ ] Log level control (DEBUG, INFO, WARN, ERROR)

**Use Case:** Print debug info without modifying kernel code

```c
// Example usage (future)
klog(LOG_DEBUG, "Page table initialized at 0x%x", page_table_addr);
klog(LOG_ERROR, "Memory allocation failed");
```

#### Keyboard Input
- [ ] PS/2 keyboard driver
- [ ] Scan code translation
- [ ] Key buffer (circular)
- [ ] Special key handling (Shift, Ctrl, Alt)
- [ ] Console input/output integration

**Use Case:** Interactive kernel shell or bootloader menu

```c
// Example usage (future)
char key = read_key();
if (key >= 'a' && key <= 'z') {
    // Handle keyboard input
}
```

#### Kernel Panic Handler
- [ ] Panic function
- [ ] Dump registers
- [ ] Show stack trace
- [ ] Display error message
- [ ] Halt cleanly

**Use Case:** Graceful failure and debugging

```c
// Example usage (future)
if (!page_table) {
    kernel_panic("Failed to allocate page table");
}
```

---

### Phase 2: Process Management (v0.3.0)
**Target: Q4 2026**

#### Process/Task Structure
- [ ] Task Control Block (TCB) structure
- [ ] Task states (RUNNING, READY, BLOCKED, TERMINATED)
- [ ] Task queue management
- [ ] Context switching
- [ ] Task scheduling

**Use Case:** Run multiple tasks concurrently

```c
// Example usage (future)
struct task *idle_task = create_task(idle_main, PRIORITY_LOW);
struct task *app_task = create_task(app_main, PRIORITY_HIGH);
schedule_task(idle_task);
schedule_task(app_task);
```

#### Memory Management
- [ ] Heap allocator (malloc/free)
- [ ] Memory fragmentation detection
- [ ] Memory profiling
- [ ] Leak detection
- [ ] Separate kernel and user heaps

**Use Case:** Dynamic memory allocation for structures

```c
// Example usage (future)
struct process *proc = kmalloc(sizeof(struct process));
kfree(proc);
```

#### Interrupt Handling
- [ ] IDT (Interrupt Descriptor Table) setup
- [ ] Exception handlers (General Protection Fault, etc.)
- [ ] Timer interrupt (for preemption)
- [ ] IRQ handlers framework
- [ ] Interrupt prioritization

**Use Case:** Respond to hardware and CPU events

```c
// Example usage (future)
register_irq_handler(IRQ_TIMER, timer_handler);
register_exception_handler(EXCEPTION_GPF, gpf_handler);
```

---

### Phase 3: Storage & I/O (v0.4.0)
**Target: Q1 2027**

#### Disk Driver
- [ ] ATA/SATA driver
- [ ] Sector read/write
- [ ] DMA support
- [ ] Error handling
- [ ] Disk caching

**Use Case:** Load programs and data from disk

```c
// Example usage (future)
sector_t *sectors = disk_read(0, 10);  // Read 10 sectors
```

#### Filesystem
- [ ] FAT32 filesystem support
- [ ] File operations (open, read, write, close)
- [ ] Directory navigation
- [ ] File creation/deletion
- [ ] Attributes (read-only, archive, etc.)

**Use Case:** Store and retrieve files

```c
// Example usage (future)
file_t *f = fs_open("/boot/loader.bin");
fs_read(f, buffer, 512);
fs_close(f);
```

#### Virtual Memory v2
- [ ] Demand paging (lazy allocation)
- [ ] Copy-on-write
- [ ] Memory mapping
- [ ] Swap support
- [ ] Memory statistics

---

### Phase 4: User Mode & System Calls (v0.5.0)
**Target: Q2 2027**

#### User Mode Transition
- [ ] Ring 3 (user mode) support
- [ ] Privilege level separation
- [ ] User/kernel memory protection
- [ ] Safe transitions between modes
- [ ] User stack management

**Use Case:** Run untrusted programs safely

#### System Calls
- [ ] System call interface (sysenter/sysexit or int 0x80)
- [ ] System call dispatcher
- [ ] Common syscalls:
  - [ ] exit() - Terminate process
  - [ ] write() - Write to console/file
  - [ ] read() - Read from console/file
  - [ ] open() - Open file
  - [ ] close() - Close file
  - [ ] fork() - Create child process
  - [ ] exec() - Execute new program
  - [ ] wait() - Wait for child
  - [ ] sleep() - Sleep for duration

**Use Case:** Allow user programs to interact with kernel

```c
// Example usage (future in user program)
write(STDOUT, "Hello from user mode!\n", 22);
pid_t child = fork();
```

---

### Phase 5: Security & Optimization (v0.6.0)
**Target: Q3 2027**

#### Security Features
- [ ] Stack canaries (detect buffer overflows)
- [ ] ASLR (Address Space Layout Randomization)
- [ ] Input validation
- [ ] Bounds checking
- [ ] Permission system (rwx bits)
- [ ] File permissions (user/group/other)

**Use Case:** Prevent common security vulnerabilities

#### Performance
- [ ] Instruction cache optimization
- [ ] TLB management
- [ ] Prefetching
- [ ] Branch prediction optimization
- [ ] Lock-free data structures

---

### Phase 6: Advanced Features (v0.7.0+)
**Target: Q4 2027+**

#### Networking (Future)
- [ ] Network driver
- [ ] IP stack
- [ ] TCP/UDP protocols
- [ ] DNS support
- [ ] Socket API

#### Multi-Processor (Future)
- [ ] SMP (Symmetric Multi-Processing)
- [ ] Multi-core CPU support
- [ ] Inter-processor communication
- [ ] Spinlock synchronization
- [ ] Load balancing

#### Dynamic Linking (Future)
- [ ] Shared libraries (.so)
- [ ] Dynamic loader
- [ ] Symbol resolution
- [ ] Lazy binding

#### ARM64 Support (Future)
- [ ] ARM64 bootloader
- [ ] ARM64 kernel code
- [ ] ARM64 paging
- [ ] ARM64 interrupts

---

## Feature Matrix

| Feature | v0.1 | v0.2 | v0.3 | v0.4 | v0.5 | v0.6 | Status |
|---------|------|------|------|------|------|------|--------|
| Bootloader | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| VGA Output | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Serial Debug | ❌ | ⏳ | ⏳ | ✅ | ✅ | ✅ | Planned |
| Keyboard | ❌ | ⏳ | ⏳ | ✅ | ✅ | ✅ | Planned |
| Paging | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Memory Allocator | ❌ | ❌ | ⏳ | ✅ | ✅ | ✅ | Planned |
| Interrupts | ❌ | ❌ | ⏳ | ✅ | ✅ | ✅ | Planned |
| Task Switching | ❌ | ❌ | ⏳ | ✅ | ✅ | ✅ | Planned |
| Disk I/O | ❌ | ❌ | ❌ | ⏳ | ✅ | ✅ | Planned |
| Filesystem | ❌ | ❌ | ❌ | ⏳ | ✅ | ✅ | Planned |
| User Mode | ❌ | ❌ | ❌ | ❌ | ⏳ | ✅ | Planned |
| System Calls | ❌ | ❌ | ❌ | ❌ | ⏳ | ✅ | Planned |
| Security | ❌ | ❌ | ❌ | ❌ | ❌ | ⏳ | Planned |
| Networking | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Future |
| SMP | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Future |

---

## Development Priorities

### High Priority (Next)
1. Serial port debugging - Essential for development
2. Keyboard input - Required for user interaction
3. Interrupt handling - Foundation for everything else
4. Memory allocator - Core utility for all features

### Medium Priority
5. Disk I/O driver
6. Basic filesystem
7. Process management
8. Task switching

### Lower Priority
9. User mode separation
10. System calls
11. Security features
12. Multi-processor support

---

## How to Contribute

### Adding New Features

1. **Create an issue** - Describe the feature and get feedback
2. **Create a branch** - `git checkout -b feature/my-feature`
3. **Implement** - Follow coding standards
4. **Test** - Add unit and integration tests
5. **Document** - Update ARCHITECTURE.md and code comments
6. **Submit PR** - Request review from maintainers
7. **Update FEATURES.md** - Mark feature as complete

### Feature Request Process

1. Check existing features in FEATURES.md
2. Check open GitHub issues
3. Create new issue with:
   - Clear description
   - Use case (why is it needed?)
   - Proposed implementation (if known)
   - Estimated effort (small/medium/large)

---

## Success Criteria

Each feature release should meet:
- ✅ All unit tests pass
- ✅ All integration tests pass
- ✅ Code coverage > 80%
- ✅ Documentation complete
- ✅ No new warnings (with -Wall -Wextra)
- ✅ Performance acceptable
- ✅ No security regressions
