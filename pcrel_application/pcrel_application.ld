/* The following values should NOT be modified. PC relative applications
 * have no fixed base address - they may be loaded and executed anywhere in
 * memory. For simplicity sake we consider it to start from address 0.
 *
 * Relative operations are limited to a range of +/- 32K on the 68000 CPU
 * due to offsets being specified using a signed 16 bit value. This places
 * an effective size limitation of 32K on the total application size for all
 * code and data.
 */
_rom_base = 0;
_rom_sz = 32K;

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
        _text_end = .;
    } > code

    .rodata : AT(_text_end) {
        _rodata_start = .;
        *(.rodata .rodata.*)
        _rodata_end = .;
    } > code

    .data : AT(_rodata_end) {
        _data_start = .;
        *(.data .data.*)
        _data_end = .;
    } > code

    .bss : AT(_data_end) {
        _bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        _bss_end = .;
    } > code
}
