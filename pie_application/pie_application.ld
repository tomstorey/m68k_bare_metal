/*
 * Modify the ROM and RAM base and sz (size) variables below to
 * suit your systems memory layout.
 *
 *   base indicates at what address a memory begins
 *   sz indicates the size of that memory
 *
 * Values can be specified in decimal, hexadecimal, or as units such
 * as 1K or 1M.
 */
_rom_base = 0;
_rom_sz = 1M;

STARTUP(crt0.o)
OUTPUT_ARCH(m68k)

__rom_end = (_rom_base + _rom_sz);

__code_start = _rom_base;
__code_sz = _rom_sz;

MEMORY {
    code (rwx) : ORIGIN = __code_start, LENGTH = __code_sz
}

SECTIONS {
    .text : {
        _text_start = .;
        *(.text .text.*)
        . = ALIGN(2);
        _text_end = .;
    } > code

    .got : AT(_text_end) {
        _got_start = .;
        *(.got .got.*)
        _got_end = .;
        . = ALIGN(2);
    } > code

    .data : AT(_got_end) {
        _data_start = .;
        *(.rodata .rodata.*)
        *(.data .data.*)
        . = ALIGN(2);
        _data_end = .;
    } > code

    .bss : AT(_data_end) {
        _bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(2);
        _bss_end = .;
    } > code
}
