;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file main64.asm
;; @brief 64-bit kernel entry point - Initialize 64-bit environment and call C code
;;
;; This module serves as the bridge between the 32-bit bootloader
;; (main.asm) and the main C kernel code. It performs minimal setup
;; required for 64-bit x86-64 execution, then jumps to kernel_main().
;;
;; Execution Context:
;;   - CPU is already in 64-bit long mode (set up by main.asm)
;;   - Paging is enabled with identity mapping
;;   - GDT is loaded with 64-bit code segment
;;   - Interrupts are NOT yet enabled
;;
;; What This Module Does:
;;   1. Zero segment registers (required for 64-bit mode)
;;   2. Call C function kernel_main()
;;   3. Halt CPU (kernel_main should not return)
;;
;; What This Module Does NOT Do:
;;   - Set up interrupt handlers (IDT) - not yet implemented
;;   - Initialize task state segment (TSS) - not needed for single-task kernel
;;   - Set up user mode - kernel runs in supervisor mode
;;   - Create process/thread structures - not yet implemented
;;
;; @note This code runs in 64-bit long mode (bits 64)
;; @note The C code (kernel_main) may not return; if it does, CPU halts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

global long_mode_start
extern kernel_main

section .text
bits 64                           ;; Assemble for 64-bit x86-64 mode


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 64-BIT KERNEL ENTRY POINT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; @brief 64-bit kernel entry point
;;
;; This is the first function executed in 64-bit mode. It performs final
;; setup steps and then calls the C kernel code (kernel_main).
;;
;; Execution Context (upon entry):
;;   - CPU: x86-64, long mode enabled
;;   - Paging: enabled with identity mapping (virtual = physical)
;;   - Interrupts: DISABLED (IF flag = 0)
;;   - Segments:
;;     - CS (Code Segment): 64-bit code segment selector (from GDT)
;;     - SS (Stack Segment): may contain garbage from 32-bit mode
;;     - DS, ES, FS, GS (Data Segments): may contain garbage
;;   - Registers:
;;     - RSP: points to kernel stack (set by main.asm)
;;     - RIP: at the instruction following the far jump
;;   - Memory: page tables and stack initialized by main.asm
;;
;; What We Must Do:
;;   In 64-bit long mode, the segment registers (DS, ES, FS, GS, SS) are
;;   ignored for memory operations - the memory model is "flat". However,
;;   some processor operations still check segment registers, so they should
;;   be zeroed for safety.
;;
;; Inputs:
;;   None (system initialized by bootloader)
;;
;; Outputs:
;;   Calls kernel_main() from C code
;;
;; Clobbers:
;;   All registers (AX, BX, CX, DX, SI, DI, BP, SP, R8-R15)
;;
long_mode_start:
	;; === ZERO SEGMENT REGISTERS ===
	;; Although segment registers are largely ignored in 64-bit flat memory
	;; model, some operations still validate them. We set them all to 0
	;; (null segment) for cleanliness and potential compatibility.

	;; Set AX to 0 (we'll use it for all segment registers)
	mov ax, 0

	;; Zero the data segment register (DS)
	;; Used by default for memory addressing
	mov ss, ax                    ;; SS = 0 (stack segment)

	;; Zero the stack segment (SS)
	;; Although we have a valid stack (RSP from bootloader),
	;; set SS to 0 for consistency
	mov ds, ax                    ;; DS = 0 (data segment)

	;; Zero extra segment registers (ES)
	;; Rarely used, but zero for cleanliness
	mov es, ax                    ;; ES = 0 (extra segment)

	;; Zero FS and GS
	;; These are sometimes used for TLS (Thread Local Storage)
	;; in modern OSes, but we zero them here
	mov fs, ax                    ;; FS = 0 (extra segment)
	mov gs, ax                    ;; GS = 0 (extra segment)

	;; === CALL C KERNEL CODE ===
	;; The C code at kernel_main() contains the real kernel logic.
	;; By convention, x86-64 ABI specifies that:
	;;   - Parameters are passed in RDI, RSI, RDX, RCX, R8, R9
	;;   - Return value is in RAX
	;;   - We must preserve RBX, RBP, R12-R15, RSP across calls
	;;
	;; kernel_main() is a C function with signature:
	;;   void kernel_main(void);
	;;
	;; It takes no parameters and returns void.
	call kernel_main              ;; Call into C code (see src/impl/kernel/main.c)
	                               ;; This function initializes the kernel,
	                               ;; prints welcome message, and may run
	                               ;; the main kernel loop

	;; === HALT CPU ===
	;; If kernel_main() ever returns (which it shouldn't in a real kernel),
	;; we halt the CPU to prevent wild code execution.
	hlt                           ;; Halt the processor
	                               ;; Disables interrupts and stops execution
	                               ;; Requires an interrupt to wake up
