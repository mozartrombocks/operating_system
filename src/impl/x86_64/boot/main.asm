;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file main.asm
;; @brief 32-bit bootloader stage - Initialize 64-bit kernel environment
;;
;; This assembly module performs the critical transition from 32-bit protected
;; mode (as established by GRUB) to 64-bit long mode. It verifies CPU
;; capabilities, sets up paging structures, and configures the processor before
;; jumping to the 64-bit kernel code.
;;
;; Execution Flow:
;;   1. GRUB hands control here in 32-bit protected mode
;;   2. Verify multiboot2 specification compliance
;;   3. Check CPU for CPUID support
;;   4. Verify 64-bit long mode support
;;   5. Configure 4-level page tables (identity mapping)
;;   6. Enable Physical Address Extension (PAE)
;;   7. Enable long mode via MSR
;;   8. Enable paging via control registers
;;   9. Load 64-bit GDT
;;   10. Jump to 64-bit code (main64.asm)
;;
;; Register Conventions (x86-32):
;;   EAX = Scratch / Return value
;;   EBX = Bootloader info pointer (set by GRUB)
;;   ECX = Scratch
;;   EDX = Scratch
;;   ESP = Stack pointer (set to stack_top)
;;
;; @note This code runs in 32-bit protected mode (bits 32)
;; @note All jump destinations must be 32-bit addresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

global start
extern long_mode_start

section .text
bits 32                          ;; Assemble for 32-bit protected mode


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ENTRY POINT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start:
	;; === INITIALIZE STACK ===
	;; GRUB does not set up a stack, so we must do it ourselves.
	;; Point ESP to top of our allocated stack memory.
	mov esp, stack_top           ;; ESP = top of stack (4KB stack allocated below)

	;; === PERFORM CPU CAPABILITY CHECKS ===
	;; Verify that this system can run our kernel
	call check_multiboot          ;; Verify GRUB multiboot2 signature
	call check_cpuid              ;; Verify CPUID instruction support
	call check_long_mode          ;; Verify 64-bit long mode support

	;; === SETUP PAGING STRUCTURES ===
	;; Initialize 4-level page tables for identity mapping (virtual = physical)
	call setup_page_tables        ;; Configure L4, L3, L2 tables

	;; === ENABLE PAGING ===
	;; Activate virtual memory through page tables and control registers
	call enable_paging            ;; Enable PAE → long mode → paging

	;; === LOAD 64-BIT GDT ===
	;; The Global Descriptor Table must be loaded before switching to long mode.
	;; The GDT defines code and data segments for 64-bit mode.
	lgdt [gdt64.pointer]          ;; Load GDT: size (word) at [gdt64.pointer]
	                               ;;           address (dword) at [gdt64.pointer+2]

	;; === JUMP TO 64-BIT CODE ===
	;; The "far jump" with selector:offset changes the code segment and
	;; transitions to 64-bit mode. The selector is index into the GDT.
	;; gdt64.code_segment contains the byte offset of the code descriptor
	;; in the GDT, and long_mode_start is our 64-bit entry point.
	jmp gdt64.code_segment:long_mode_start


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CPU CAPABILITY CHECKS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; @brief Verify multiboot2 compliance
;;
;; GRUB sets EAX to a magic number (0x36d76289) before calling the kernel.
;; This confirms that the bootloader is multiboot2-compliant.
;;
;; Inputs:
;;   EAX = Multiboot magic number (set by GRUB)
;;
;; Outputs:
;;   None (success) / Error via error handler (failure)
;;
;; Modifies:
;;   None (except flags register)
;;
check_multiboot:
	;; Compare EAX against magic number
	cmp eax, 0x36d76289          ;; Expected: 0x36d76289 (multiboot2)

	;; If not equal, jump to error handler with code 'M'
	jne .no_multiboot             ;; Error: not multiboot2 compliant

	ret                           ;; Success: return to caller

.no_multiboot:
	mov al, 'M'                   ;; Set error code to 'M' (Multiboot error)
	jmp error                     ;; Jump to error handler (no return)


;;
;; @brief Verify CPUID instruction support
;;
;; The CPUID instruction is required to detect CPU capabilities like long mode.
;; We verify CPUID support by toggling bit 21 of the EFLAGS register. If we can
;; flip this bit, the CPU supports CPUID.
;;
;; Algorithm:
;;   1. Push EFLAGS to stack
;;   2. Pop into EAX
;;   3. Toggle bit 21 (ID flag)
;;   4. Push modified value back to EFLAGS
;;   5. Read EFLAGS again into EAX
;;   6. Compare original and new values
;;   7. If equal (couldn't flip bit): CPUID not supported
;;
;; Inputs:
;;   None
;;
;; Outputs:
;;   None (success) / Error handler (failure)
;;
;; Clobbers:
;;   EAX, ECX
;;
check_cpuid:
	;; === SAVE ORIGINAL EFLAGS ===
	pushfd                       ;; Push EFLAGS onto stack
	pop eax                       ;; Pop into EAX for inspection
	mov ecx, eax                  ;; ECX = original EFLAGS for comparison

	;; === TOGGLE CPUID FLAG (BIT 21) ===
	xor eax, 1 << 21              ;; XOR bit 21 (toggle it)
	push eax                       ;; Push modified value to stack
	popfd                         ;; Pop into EFLAGS (apply toggle)

	;; === VERIFY TOGGLE WAS SUCCESSFUL ===
	pushfd                        ;; Push EFLAGS (with attempted change)
	pop eax                       ;; Pop into EAX
	push ecx                       ;; Restore original EFLAGS
	popfd

	;; If EAX == ECX, the bit didn't toggle → CPUID not supported
	cmp eax, ecx                  ;; Compare modified vs. original
	je .no_cpuid                  ;; Error: CPUID not supported

	ret                           ;; Success: CPUID is available

.no_cpuid:
	mov al, 'C'                   ;; Set error code to 'C' (CPUID error)
	jmp error                     ;; Jump to error handler


;;
;; @brief Verify 64-bit long mode support
;;
;; Uses CPUID to check if the CPU supports long mode (IA-32e / x86-64).
;; We specifically check:
;;   - CPUID leaf 0x80000000 to verify extended leaves are available
;;   - CPUID leaf 0x80000001 for the LM flag (bit 29 of EDX)
;;
;; Algorithm:
;;   1. Call CPUID with EAX = 0x80000000 (get extended CPUID info)
;;   2. Check if result >= 0x80000001 (extended leaves available)
;;   3. Call CPUID with EAX = 0x80000001 (CPU features)
;;   4. Check bit 29 of EDX (long mode support)
;;
;; Inputs:
;;   None
;;
;; Outputs:
;;   None (success) / Error handler (failure)
;;
;; Clobbers:
;;   EAX, EDX
;;
check_long_mode:
	;; === CHECK EXTENDED CPUID SUPPORT ===
	mov eax, 0x80000000          ;; CPUID leaf: get extended info limit
	cpuid                         ;; Processor identifies itself

	cmp eax, 0x80000001          ;; Check if leaf 0x80000001 is available
	jb .no_long_mode              ;; Error: extended leaves not available

	;; === CHECK LONG MODE FLAG ===
	mov eax, 0x80000001          ;; CPUID leaf: extended CPU features
	cpuid                         ;; Call CPUID

	;; Test bit 29 of EDX (long mode flag, also called LM or IA-32e)
	test edx, 1 << 29             ;; Check if bit 29 (LM flag) is set
	jz .no_long_mode              ;; Error: long mode not supported

	ret                           ;; Success: long mode is available

.no_long_mode:
	mov al, 'L'                   ;; Set error code to 'L' (Long mode error)
	jmp error                     ;; Jump to error handler


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PAGING SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; @brief Initialize 4-level page table hierarchy
;;
;; Intel x86-64 uses a 4-level paging structure:
;;   Level 4 (PML4): Page Map Level 4 - top level
;;   Level 3 (PDPT): Page Directory Pointer Table
;;   Level 2 (PDT):  Page Directory Table
;;   Level 1 (PT):   Page Table (not used in this implementation)
;;
;; For simplicity, we use 2MB huge pages (large page support), which
;; allows us to map 512 entries × 2MB = 1GB per L2 table.
;;
;; Memory Layout:
;;   - L4 table:  4KB, single entry points to L3
;;   - L3 table:  4KB, single entry points to L2
;;   - L2 table:  4KB, 512 entries (one per 2MB huge page)
;;   - Total: 1GB virtual memory mapped with identity mapping
;;
;; Page Table Entry Flags:
;;   Bit 0 (0x1):  Present flag (must be set)
;;   Bit 1 (0x2):  Writeable flag (must be set for kernel)
;;   Bit 7 (0x80): Huge page flag (L2 entries only)
;;
;; Algorithm:
;;   1. Set L4[0] = L3 base address | 0x3 (present, writable)
;;   2. Set L3[0] = L2 base address | 0x3 (present, writable)
;;   3. Loop for i = 0 to 511:
;;        L2[i] = (i * 2MB) | 0x83 (present, writable, huge page)
;;
;; Inputs:
;;   None
;;
;; Outputs:
;;   CR3 is NOT modified (done in enable_paging())
;;
;; Clobbers:
;;   EAX, ECX
;;
setup_page_tables:
	;; === SETUP L4 TABLE ===
	;; L4 table entry 0 points to L3 table
	mov eax, page_table_l3        ;; EAX = L3 table base address
	or eax, 0b11                  ;; Set present (bit 0) and writable (bit 1)
	mov [page_table_l4], eax      ;; L4[0] = L3 address | 0b11

	;; === SETUP L3 TABLE ===
	;; L3 table entry 0 points to L2 table
	mov eax, page_table_l2        ;; EAX = L2 table base address
	or eax, 0b11                  ;; Set present and writable
	mov [page_table_l3], eax      ;; L3[0] = L2 address | 0b11

	;; === SETUP L2 TABLE (HUGE PAGES) ===
	;; Fill L2 with 512 2MB huge page entries
	;; Each entry maps one 2MB region (0, 2MB, 4MB, ... 1024MB)
	mov ecx, 0                    ;; ECX = loop counter (0-511)

.loop:
	;; === CALCULATE PHYSICAL ADDRESS ===
	;; Each L2 entry covers one 2MB region
	;; Physical address = counter × 2MB
	mov eax, 0x200000             ;; EAX = 2MB (one huge page size)
	mul ecx                        ;; EAX = ECX × 2MB (physical address)

	;; === SET PAGE FLAGS ===
	;; Flags: 0x83 = 0b10000011
	;;   Bit 0: Present (1 = page is in memory)
	;;   Bit 1: Writable (1 = allows writes)
	;;   Bit 7: Huge page (1 = 2MB/4MB instead of 4KB)
	or eax, 0b10000011            ;; OR in present, writable, huge page flags

	;; === STORE IN L2 TABLE ===
	;; L2 tables are arrays of 64-bit entries (8 bytes each in long mode)
	;; But we're in 32-bit mode, so NASM handles the addressing:
	;; [page_table_l2 + ECX*8] = entry for table index ECX
	mov [page_table_l2 + ecx * 8], eax

	;; === LOOP UNTIL ALL ENTRIES FILLED ===
	inc ecx                       ;; ECX++ (next entry)
	cmp ecx, 512                  ;; Have we filled all 512 entries?
	jne .loop                     ;; If not, continue loop

	ret                           ;; All page tables configured


;;
;; @brief Enable paging and switch to long mode
;;
;; This function performs the final processor configuration to enable 64-bit
;; long mode operation:
;;   1. Load CR3 with page table base address
;;   2. Enable PAE (Physical Address Extension, 36-bit addresses)
;;   3. Enable long mode via EFER MSR
;;   4. Enable paging via CR0
;;
;; Control Register Bits:
;;   CR3:   Page table base address (bits 12-31 for page-aligned address)
;;   CR4:   Bit 5 = PAE (Physical Address Extension)
;;   MSR:   Bit 8 = EFER.LME (Long Mode Enable)
;;   CR0:   Bit 31 = PG (Paging enable)
;;
;; After this function, the processor will be in long mode when we execute
;; a far jump with a 64-bit code segment.
;;
;; Inputs:
;;   None (page tables already set up by setup_page_tables())
;;
;; Outputs:
;;   CR3, CR4, CR0 modified; EFER MSR modified
;;   CPU now supports 64-bit instructions (but still in 32-bit mode)
;;
;; Clobbers:
;;   EAX, ECX
;;
enable_paging:
	;; === PASS PAGE TABLE LOCATION TO CPU ===
	;; CR3 register holds the physical address of the top-level page table.
	;; The lower 12 bits must be 0 (page-aligned), and upper bits contain
	;; the address. Our page table is at label page_table_l4.
	mov eax, page_table_l4        ;; EAX = L4 page table base
	mov cr3, eax                  ;; CR3 = page table (enables virtual addressing)

	;; === ENABLE PHYSICAL ADDRESS EXTENSION (PAE) ===
	;; PAE allows use of 36-bit physical addresses (supports >4GB RAM).
	;; This is required for long mode.
	;; CR4 bit 5 = PAE flag
	mov eax, cr4                  ;; EAX = current CR4
	or eax, 1 << 5                ;; Set bit 5 (PAE)
	mov cr4, eax                  ;; CR4 = modified value

	;; === ENABLE LONG MODE ===
	;; Long mode is enabled via the EFER (Extended Feature Enable Register) MSR.
	;; EFER is accessed via RDMSR (read) and WRMSR (write) instructions.
	;; EFER MSR address: 0xC0000080
	;; EFER bit 8: LME (Long Mode Enable)
	mov ecx, 0xC0000080           ;; ECX = EFER MSR address
	rdmsr                         ;; Read EFER into EDX:EAX
	or eax, 1 << 8                ;; Set bit 8 (LME flag)
	wrmsr                         ;; Write back to EFER

	;; === ENABLE PAGING ===
	;; Paging is controlled by the PG flag in CR0.
	;; CR0 bit 31 = PG (Paging enable)
	;; WARNING: Enabling paging with invalid page tables causes a fault!
	;; Our page tables are valid (set up above), so this is safe.
	mov eax, cr0                  ;; EAX = current CR0
	or eax, 1 << 31               ;; Set bit 31 (PG flag)
	mov cr0, eax                  ;; CR0 = modified value (PAGING ENABLED!)

	ret                           ;; Paging and long mode are now active


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ERROR HANDLER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; @brief Halt system and display error code
;;
;; Called when a critical error is detected (invalid multiboot, no CPUID, etc.).
;; Displays "ERR: X" where X is an ASCII error code, then halts the CPU.
;;
;; The message is written directly to VGA text mode buffer at 0xb8000.
;;
;; Inputs:
;;   AL = Error code character (e.g., 'M', 'C', 'L')
;;
;; Outputs:
;;   Display shows "ERR: X" and CPU halts (never returns)
;;
;; Message Layout in VGA Buffer (0xb8000):
;;   [0x00] = 'E'  [0x01] = 0x4F (white on red background)
;;   [0x02] = 'R'  [0x03] = 0x4F
;;   [0x04] = 'R'  [0x05] = 0x4F
;;   [0x06] = ':'  [0x07] = 0x4F
;;   [0x08] = ' '  [0x09] = 0x4F
;;   [0x0A] = X    (error code)
;;
;; Note: Color is set separately for each character
;;
error:
	;; === WRITE "ERR: " TO VIDEO BUFFER ===
	;; VGA text mode: each cell is 2 bytes (character + attribute)
	;; Attribute 0x4F = white text (0x0F) on red background (0x40)
	;; Offset 0xb8000 = start of video buffer

	;; Write 'E' at offset 0
	mov dword [0xb8000], 0x4f524f45  ;; Dword writes 4 bytes at once:
	                                   ;; 'E' + color + 'R' + color

	;; Write 'R:' and space at offset 4
	mov dword [0xb8004], 0x4f3a4f52  ;; 'R' + color + ':' + color

	;; Write space at offset 8
	mov dword [0xb8008], 0x4f204f20  ;; ' ' + color + ' ' + color

	;; Write error code character at offset 10
	mov byte [0xb800a], al            ;; Write AL (error code) to video buffer

	;; === HALT CPU ===
	hlt                           ;; Halt processor (infinite loop)
	                               ;; Execution never continues from here


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA SECTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .bss
;; The .bss section is for uninitialized data that consumes space in the
;; binary image but contains no initialization data. Useful for large
;; static buffers like page tables and stacks.

align 4096                        ;; Align to 4KB (page boundary)

;;
;; @brief Level 4 page table (top-level paging structure)
;;
;; This is the top-level paging table referenced by CR3. For our simple
;; 1GB memory map, only the first entry is used (pointing to L3).
;;
page_table_l4:
	resb 4096                     ;; Reserve 4096 bytes (one page)

;;
;; @brief Level 3 page table (page directory pointer table)
;;
;; This table is referenced by L4[0]. For our implementation, only the
;; first entry is used (pointing to L2).
;;
page_table_l3:
	resb 4096

;;
;; @brief Level 2 page table (page directory with huge pages)
;;
;; Contains 512 entries for 2MB huge pages. With identity mapping:
;;   Entry 0:   Maps 0x00000000 - 0x001FFFFF (0-2MB)
;;   Entry 1:   Maps 0x00200000 - 0x003FFFFF (2-4MB)
;;   ...
;;   Entry 511: Maps 0x3FE00000 - 0x3FFFFFFF (1022-1024MB)
;;
page_table_l2:
	resb 4096

;;
;; @brief Kernel stack (4 pages = 16KB)
;;
;; The stack grows downward in x86 (lower addresses = deeper stack).
;; Stack pointer (ESP/RSP) points to the next free location.
;; We allocate 16KB of stack space (4 × 4KB pages).
;;
;; Layout:
;;   stack_top:    Highest address (stack starts here, grows down)
;;   ...
;;   stack_bottom: Lowest address
;;
stack_bottom:
	resb 4096 * 4                 ;; Reserve 16KB for stack

stack_top:
	;; ESP will be set to this address by the bootloader entry code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY DATA SECTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .rodata
;; Read-only data that can be stored in ROM or marked read-only in memory.

;;
;; @brief Global Descriptor Table (GDT) for 64-bit mode
;;
;; The GDT defines the memory segments available in the system. In 64-bit mode,
;; most of the segment information is ignored by the processor, but we must
;; still define a code segment descriptor to satisfy the jmp instruction.
;;
;; Structure:
;;   dq 0x0000: Null descriptor (required, unused)
;;   dq CODE:   64-bit code descriptor
;;   Pointer:   Contains table size and address
;;
;; 64-bit Code Descriptor Encoding:
;;   Bit 43: 1 (code segment)
;;   Bit 44: 1 (conforming - not used in 64-bit)
;;   Bit 47: 1 (present)
;;   Bit 53: 1 (64-bit code segment)
;;
gdt64:
	dq 0                          ;; Null descriptor (required by x86)

.code_segment: equ $ - gdt64      ;; Define constant = current position (offset in GDT)
	                               ;; This becomes the selector for jmp instruction
	dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)
	                               ;; 64-bit code segment descriptor:
	                               ;;   Bit 43: executable code
	                               ;;   Bit 44: direction/conforming
	                               ;;   Bit 47: present (1 = valid)
	                               ;;   Bit 53: 64-bit long mode

;;
;; @brief GDT Pointer (used by LGDT instruction)
;;
;; The LGDT instruction requires a 6-byte structure:
;;   Bytes 0-1: Table size in bytes minus 1 (size - 1)
;;   Bytes 2-5: Linear address of GDT
;;
.pointer:
	dw $ - gdt64 - 1              ;; Size of GDT in bytes minus 1
	dq gdt64                      ;; Linear address of GDT
