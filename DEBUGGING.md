# Debugging Guide

Guide for debugging the OS kernel using GDB and QEMU.

---

## Quick Start

### Start Debugging

```bash
# Build and launch debugger
make debug

# This automatically:
# 1. Compiles kernel with debug symbols
# 2. Starts QEMU in debug mode
# 3. Launches GDB and connects
# 4. Sets breakpoint at kernel entry
# 5. Displays helpful commands
```

### Basic Commands

```bash
# Resume execution
(gdb) continue
(gdb) c

# Step one instruction
(gdb) step
(gdb) s

# Step one instruction (skip function calls)
(gdb) next
(gdb) n

# Quit debugger
(gdb) quit
(gdb) q
```

---

## GDB Essentials

### Setting Breakpoints

```bash
# Breakpoint at address
(gdb) break *0x100000
(gdb) b *0x100000

# Breakpoint at function
(gdb) break kernel_main
(gdb) b print_str

# Breakpoint at file:line
(gdb) break src/impl/kernel/main.c:42
(gdb) b main.c:42

# Conditional breakpoint
(gdb) break main.c:42 if i > 10
(gdb) break main.c:42 if color == 0x04

# List all breakpoints
(gdb) info breakpoints
(gdb) i b

# Delete breakpoint
(gdb) delete 1
(gdb) del 1

# Disable/enable breakpoint
(gdb) disable 1
(gdb) enable 1
```

### Inspecting Data

```bash
# Print variable value
(gdb) print color
(gdb) p color

# Print in hex
(gdb) print/x color
(gdb) p/x color

# Print in binary
(gdb) print/t color
(gdb) p/t color

# Print memory address
(gdb) print &color
(gdb) p &color

# Display format specifiers
# /x = hex
# /d = decimal
# /u = unsigned
# /t = binary
# /o = octal
# /f = float
# /a = address
```

### Examining Memory

```bash
# Show memory at address (100 bytes)
(gdb) x/100bx 0xb8000
# x = examine
# 100 = count
# b = byte size
# x = hex format

# Show memory as words (32-bit)
(gdb) x/10wx 0xb8000
# w = word (32-bit)

# Show memory as quad words (64-bit)
(gdb) x/10gx 0xb8000
# g = giant (64-bit)

# Show memory as characters/string
(gdb) x/100s 0xb8000
# s = string

# Show instructions at address
(gdb) x/10i 0x100000
# i = instruction

# Show 20 instructions forward
(gdb) x/20i $pc
# $pc = program counter
```

### Registers

```bash
# Show all registers
(gdb) info registers
(gdb) i r

# Show specific register
(gdb) print $rax
(gdb) p $rax

# Show register in different format
(gdb) print/x $rax
(gdb) p/t $rax

# Set register value
(gdb) set $rax = 0x1000

# Common x86-64 registers
# rax, rbx, rcx, rdx - general purpose
# rsi, rdi - source/destination
# rbp - base pointer (frame pointer)
# rsp - stack pointer
# rip - instruction pointer
# r8-r15 - additional registers
```

### Stack Inspection

```bash
# Show call stack
(gdb) backtrace
(gdb) bt

# Show detailed backtrace
(gdb) backtrace full
(gdb) bt full

# Show local variables
(gdb) info locals
(gdb) i lo

# Show function arguments
(gdb) info args
(gdb) i args

# Show specific frame
(gdb) frame 2
(gdb) f 2

# Show frame details
(gdb) info frame
(gdb) i f
```

---

## Debugging Workflows

### Debugging Boot Sequence

```bash
# Start debugging
make debug

# At first breakpoint (kernel entry)
(gdb) list
# Shows source code around current location

# Step through boot code
(gdb) step
(gdb) step
(gdb) step

# Check CPU registers during boot
(gdb) info registers

# Check memory at video buffer
(gdb) x/20bx 0xb8000

# Set breakpoint at kernel_main
(gdb) break kernel_main
(gdb) continue
```

### Debugging Print Function

```bash
# Set breakpoint in print_char
(gdb) break print_char
(gdb) continue

# When breakpoint hits
(gdb) info args
# Shows: character = 65 (which is 'A')

# Step through function
(gdb) step
(gdb) step

# Check buffer state
(gdb) x/10bx 0xb8000
# Shows what was written to video buffer

# Continue to next character
(gdb) continue
```

### Debugging Memory Issues

```bash
# Set watchpoint on variable
(gdb) watch color
# Breaks whenever color is written

(gdb) continue
# Will break next time color changes

# Set read/write watchpoint
(gdb) watch color
(gdb) rwatch color  # break on read
(gdb) awatch color  # break on read or write

# Conditional watchpoint
(gdb) watch color if color == 0xFF
```

### Debugging Crashes

```bash
# Run until crash
(gdb) continue

# GDB will catch exception/fault
# You'll see: Signal received: SIGSEGV

# Show where crash happened
(gdb) where
(gdb) backtrace

# Show memory around crash
(gdb) print $rip
(gdb) x/10i $rip

# Show registers at crash
(gdb) info registers
```

---

## Advanced Debugging

### Logging Execution

```bash
# Enable trace logging (very slow!)
(gdb) set logging on
# Creates gdb.txt with all commands

(gdb) set logging off

# View log
(gdb) shell cat gdb.txt | head -100
```

### Scripting GDB Commands

**Create file: debug_script.gdb**
```
# Debug script for kernel
break *0x100000
commands
    silent
    print/x $rax
    print/x $rbx
    continue
end

break kernel_main
commands
    printf "Entered kernel_main\n"
    continue
end

continue
```

**Run script:**
```bash
gdb -x debug_script.gdb kernel_binary
```

### Python Scripting (Advanced)

```python
# In GDB
(gdb) python
import gdb

# Define custom command
class PrintPageTable(gdb.Command):
    def __init__(self):
        super(PrintPageTable, self).__init__(
            "print-pagetable",
            gdb.COMMAND_USER)
    
    def invoke(self, arg, from_tty):
        # Get page table address
        cr3 = gdb.parse_and_eval("$cr3")
        print(f"Page table at: 0x{cr3}")
        
        # Read and display entries
        for i in range(512):
            # ... custom logic ...

# Register command
PrintPageTable()
end

# Use custom command
(gdb) print-pagetable
```

### Remote Debugging

```bash
# On target (QEMU)
make debug
# QEMU starts with -s -S (listening on :1234)

# On host (another terminal)
(gdb) target remote localhost:1234
(gdb) break kernel_main
(gdb) continue
```

---

## Common Debugging Scenarios

### "What's at address X?"

```bash
# Look at one byte
(gdb) x/1bx 0x100000

# Look at 10 bytes
(gdb) x/10bx 0x100000

# Look at structure
(gdb) x/2gx 0x100000
# (assuming 64-bit structure)
```

### "What's in register X?"

```bash
# Show value
(gdb) print $rax

# Show value in hex
(gdb) print/x $rax

# Show value in binary
(gdb) print/t $rax
```

### "Why did we crash here?"

```bash
# When GDB catches crash
(gdb) backtrace full
# Shows call stack and variables

(gdb) info frame
# Shows current frame details

(gdb) x/10i $rip
# Shows instructions around crash
```

### "What are the local variables?"

```bash
(gdb) info locals
# Shows all local variables

(gdb) print variable_name
# Shows specific variable

(gdb) print &variable_name
# Shows variable address
```

### "How did we get here?"

```bash
(gdb) backtrace
# Shows call stack

(gdb) frame 1
# Switch to frame 1

(gdb) info locals
# Show variables in that frame
```

---

## Troubleshooting GDB

### "Connection refused"

Make sure QEMU is running with debug options:
```bash
make debug
# Or manually:
qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso -s -S &
gdb kernel
(gdb) target remote localhost:1234
```

### "No debugging symbols"

Rebuild with debug flags:
```bash
DEBUG=1 make build-x86_64
```

### "Breakpoint not hit"

```bash
# Verify breakpoint is set
(gdb) info breakpoints

# Check if address is correct
(gdb) symbol-file kernel_binary
(gdb) list kernel_main

# Set breakpoint at address instead
(gdb) break *0x100000
```

### "Cannot access memory"

This usually means:
- Paging not enabled yet
- Address is invalid
- Page table not set up

Try examining nearby memory or using `x/i` to disassemble.

### "GDB hangs"

Press Ctrl+C to interrupt:
```bash
(gdb) continue
# (kernel is running, GDB waiting)
^C  # Press Ctrl+C
(gdb) # Back at prompt
```

---

## Performance Debugging

### Finding Bottlenecks

```bash
# Use time command
(gdb) define time_func
    break function_name
    continue
    # Record time
    break return_point
    continue
    # Calculate elapsed time
end

# Or use instruction count
(gdb) stepi 1000
# Execute 1000 instructions
```

### Memory Leak Detection

```bash
# Use breakpoint on allocations
(gdb) break malloc
(gdb) commands
    silent
    printf "malloc(%d) -> ", $arg0
    # Your leak detection logic
    continue
end
```

---

## Useful GDB Aliases

```bash
# Add to ~/.gdbinit or define in GDB

# Short aliases
(gdb) alias s = step
(gdb) alias n = next
(gdb) alias c = continue
(gdb) alias p = print
(gdb) alias b = break
(gdb) alias del = delete
(gdb) alias bt = backtrace

# Custom aliases
(gdb) alias regs = info registers
(gdb) alias stack = backtrace full
(gdb) alias locals = info locals
```

---

## Serial Port Debugging (Future)

Once serial port driver is implemented:

```bash
# Monitor serial output in separate terminal
(gdb) shell minicom -D /dev/ttyS0 -b 9600 &

# Or with screen
(gdb) shell screen /dev/ttyS0 9600 &

# Or with socat
(gdb) shell socat - /dev/ttyS0,raw,echo=0 &
```

This will show kernel debug messages in real-time.

---

## Quick Reference Card

```
=== EXECUTION ===
c, continue       Run until breakpoint
n, next           Step over function
s, step           Step into function
ni, nexti         Next instruction
si, stepi         Step instruction
finish            Run until return
run               Start execution

=== BREAKPOINTS ===
b *0x100000       Break at address
b function        Break at function
b file:line       Break at line
watch var         Break on variable write
info b            List breakpoints
del 1             Delete breakpoint
disable/enable    Disable/enable

=== INSPECTION ===
p var             Print variable
p/x var           Print in hex
x/10bx 0xaddr     Examine memory
info registers    Show registers
info locals       Show local vars
backtrace         Show call stack

=== INFO ===
list              Show source
info frame        Current frame
info args         Function args
where             Where are we
disassemble       Show assembly
```

---

## Resources

- [GDB Manual](https://sourceware.org/gdb/documentation/)
- [GDB Quick Reference](https://www.gnu.org/software/gdb/support/)
- [QEMU Debugging](https://wiki.qemu.org/Debugging/Tips)
- [x86-64 Architecture](https://en.wikipedia.org/wiki/X86-64)

---

## Tips & Tricks

✅ **DO:**
- Use `info breakpoints` frequently
- Set breakpoints at suspicious locations
- Use watchpoints to catch variable changes
- Save debugging scripts in `gdb.ini`
- Take notes of interesting memory addresses

❌ **DON'T:**
- Leave breakpoints while running in production
- Use `step` in tight loops (too slow)
- Modify memory directly (usually)
- Ignore stack traces
- Forget to rebuild after code changes

Happy debugging! 🐛🔍
