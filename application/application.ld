/*
 * Modify the ROM and RAM base and sz (size) variables below to
 * suit your systems memory layout.
 *
 *   base indicates at what address a memory begins
 *   sz indicates the size of that memory
 */
__rom_base = 0;
__rom_sz = 0x100000;
__ram_base = 0x100000;
__ram_sz = 0x100000;

/*
 * Dont modify below this line (unless you know what youre doing),
 * except to add user interrupt vectors.
 */

STARTUP(crt0.o)
OUTPUT_ARCH(m68k)

PROVIDE(__rom_end = (__rom_base + __rom_sz));
PROVIDE(__ram_end = (__ram_base + __ram_sz));

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
        . = ALIGN(0x2);
        *(.text *.text.* text text.*)
        . = ALIGN(0x10);
        _text_end = .;
    } > text

    .rodata : AT(_text_end) {
        *(.rodata)
        . = ALIGN(0x10);
        _rodata_end = .;
    } > text

    .data : AT(_rodata_end) {
        . = ALIGN(0x4);
        _data_start = .;
        *(.data)
        . = ALIGN(0x4);
        _data_end = .;
    } > data

    .bss : {
        _bss_start = .;
        *(.bss)
        *(COMMON)
        . = ALIGN(0x4);
        _bss_end = .;
    } > data
}
