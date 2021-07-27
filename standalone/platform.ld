/*
 * Modify the ROM and RAM base and sz (size) variables below to
 * suit your systems memory layout.
 *
 *   base indicates at what address a memory begins
 *   sz indicates the size of that memory
 *
 * Values can be specified in decimal, hexadecimal, or as units such
 * as 1K or 1M.
 *
 * Space for the stack may also be reserved here. The heap will then
 * consume all remaining RAM between the end of the .bss section and
 * the lowest address reserved for the stack.
 *
 * Since there are no controls in place to ensure the stack does not
 * grow into the heap, the user is responsible for reserving sufficient
 * stack space to prevent it overwriting the upper areas of the heap.
 */
__rom_base = 0;
__rom_sz = 1M;
__ram_base = 0x100000;
__ram_sz = 1M;

__stack_sz = 4K;

/*
 * Dont modify below this line (unless you know what youre doing),
 * except to add user interrupt vectors.
 */

STARTUP(crt0.o)
OUTPUT_ARCH(m68k)

__rom_end = (__rom_base + __rom_sz);
__ram_end = (__ram_base + __ram_sz);

__reset_org = __rom_base;
__ivt_org = __rom_base + 0x8;
__text_org = __rom_base + 0x400;
__text_sz = __rom_sz - 0x400;
__data_org = __ram_base;
__data_sz = __ram_sz;

MEMORY {
    reset        (r!ax) : ORIGIN = __reset_org, LENGTH = 0x8
    ivt          (r!ax) : ORIGIN = __ivt_org, LENGTH = 0x3F8
    text         (rx!w) : ORIGIN = __text_org, LENGTH = __text_sz
    data        (rwx!a) : ORIGIN = __data_org, LENGTH = __data_sz
}

SECTIONS {
    .reset : {
        LONG(__ram_end);                /* Initial SSP */
        LONG(ABSOLUTE(_start));         /* Initial PC */
    } > reset

    .ivt : {
        LONG(DEFINED(BusError) ? ABSOLUTE(BusError) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(AddressError) ? ABSOLUTE(AddressError) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IllegalInstruction) ? ABSOLUTE(IllegalInstruction) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(ZeroDivide) ? ABSOLUTE(ZeroDivide) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(CHKInstruction) ? ABSOLUTE(CHKInstruction) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAPVInstruction) ? ABSOLUTE(TRAPVInstruction) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(PrivilegeViolation) ? ABSOLUTE(PrivilegeViolation) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(Trace) ? ABSOLUTE(Trace) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(Line1010Emulator) ? ABSOLUTE(Line1010Emulator) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(Line1111Emulator) ? ABSOLUTE(Line1111Emulator) : ABSOLUTE(__DefaultInterrupt));
        . = 0x38-0x8; /* Reserved vector entries */
        LONG(DEFINED(FormatError) ? ABSOLUTE(FormatError) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(UninitializedInterruptVector) ? ABSOLUTE(UninitializedInterruptVector) : ABSOLUTE(__DefaultInterrupt));
        . = 0x60-0x8; /* Reserved vector entries */
        LONG(DEFINED(SpuriousInterrupt) ? ABSOLUTE(SpuriousInterrupt) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IRQ1) ? ABSOLUTE(IRQ1) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IRQ2) ? ABSOLUTE(IRQ2) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IRQ3) ? ABSOLUTE(IRQ3) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IRQ4) ? ABSOLUTE(IRQ4) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IRQ5) ? ABSOLUTE(IRQ5) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IRQ6) ? ABSOLUTE(IRQ6) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(IRQ7) ? ABSOLUTE(IRQ7) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP0) ? ABSOLUTE(TRAP0) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP1) ? ABSOLUTE(TRAP1) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP2) ? ABSOLUTE(TRAP2) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP3) ? ABSOLUTE(TRAP3) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP4) ? ABSOLUTE(TRAP4) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP5) ? ABSOLUTE(TRAP5) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP6) ? ABSOLUTE(TRAP6) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP7) ? ABSOLUTE(TRAP7) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP8) ? ABSOLUTE(TRAP8) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP9) ? ABSOLUTE(TRAP9) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP10) ? ABSOLUTE(TRAP10) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP11) ? ABSOLUTE(TRAP11) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP12) ? ABSOLUTE(TRAP12) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP13) ? ABSOLUTE(TRAP13) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP14) ? ABSOLUTE(TRAP14) : ABSOLUTE(__DefaultInterrupt));
        LONG(DEFINED(TRAP15) ? ABSOLUTE(TRAP15) : ABSOLUTE(__DefaultInterrupt));
        . = 0x100-0x8; /* Reserved vector entries */
/*
 *
 * User Interrupt Vectors
 *
 *   Vector #         Address
 *   Hex    Dec       Hex      Dec
 *   40-FF  64-255    100-3FC  256-1020
 *
 * To calculate the offset within the .ivt section to place your vector, use
 * the following calculation, assuming vector number = 0x50:
 *
 *   0x50 * 4 = 0x140 (address in ROM)
 *   0x140 - 8 = 0x138 (offset in .ivt section)
 *
 * Subtracting 8 is necessary since the .ivt section begins at address 0x8,
 * and origins are calculated from the beginning of each section.
 *
 * You could then place your vector at that position in the vector table as
 * follows:
 *
 *   . = 0x138;
 *   LONG(ABSOLUTE(NameOfHandlerFunction));
 */
    } > ivt

    .text : {
        _text_start = .;
        *(text text.* .text *.text.*)
        . = ALIGN(0x10);
        _text_end = .;
    } > text

    .rodata : AT(_text_end) {
        _rodata_start = .;
        *(.rodata)
        . = ALIGN(0x10);
        _rodata_end = .;
    } > text

    .data : AT(_rodata_end) {
        _data_start = .;
        *(.data)
        . = ALIGN(0x10);
        _data_end = .;
    } > data

    .bss : {
        _bss_start = .;
        *(.bss)
        *(COMMON)
        . = ALIGN(0x10);
        _bss_end = .;
    } > data

    .heap : {
        _heap_start = .;
        . += (__ram_sz - __stack_sz - SIZEOF(.bss) - SIZEOF(.data));
        _heap_end = .;
    } > data
}
