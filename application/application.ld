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
__rom_base = 0;
__rom_sz = 1M;
__ram_base = 0x100000;
__ram_sz = 1M;

/*
 * Dont modify below this line (unless you know what youre doing),
 * except to add user interrupt vectors.
 */

STARTUP(crt0.o)
OUTPUT_ARCH(m68k)

__rom_end = (__rom_base + __rom_sz);
__ram_end = (__ram_base + __ram_sz);

__text_start = __rom_base;
__text_sz = __rom_sz;
__data_start = __ram_base;
__data_sz = __ram_sz;

MEMORY {
    text         (rx!w) : ORIGIN = __text_start, LENGTH = __text_sz
    data        (rwx!a) : ORIGIN = __data_start, LENGTH = __data_sz
}

SECTIONS {
    .text : {
        _text_start = .;
        *(.text *.text.* text text.*)
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
}
