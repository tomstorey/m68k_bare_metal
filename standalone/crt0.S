        .title "crt0.S for m68k bare metal - standalone"

/* Uncomment the following if you dont want the EVT to be automatically copied
 * to RAM address 0 when the ROM has been remapped away from address 0 */
/* #define NO_ROMRAM_REMAP */

#define USEVBR (defined(mc68010) || defined(mc68020) || defined(mc68030) || \
                defined(mc68040) || defined(mc68060) || defined(mc68332))

        /* A bunch of variables supplied by the linker */
        .extern _stack_end
        .extern _rom_base
        .extern _bss_start
        .extern _bss_end
        .extern _text_end
        .extern _data_start
        .extern _data_end
        .weak hardware_init_hook
        .weak software_init_hook
        .extern main

        .section .text
        .align 2

        .type _start, @function
        .globl _start
_start:
        move.w  #0x2700, %sr            /* Mask interrupts, supervisor mode */

        movea.l #_rom_base, %sp        /* Manually configure the SP value,
                                         * this allows the SP value in the ROM
                                         * image to be used e.g. to store a
                                         * checksum instead. */

#if USEVBR
        /* If using a CPU with a VBR, point it to the beginning of ROM */
        movea.l #_rom_base, %a0
        movec   %a0, %vbr
#else /* USEVBR */
#ifndef NO_ROMRAM_REMAP
        move.l  #_rom_base, %d0         /* Skip EVT copy if ROM is at addr 0 */
        beq     1f

        move.w  #511, %d0               /* Number of words to copy, less 1 for
                                         * dbf loop */
        movea.l #_rom_base, %a0         /* Source address */
        /* For CPUs without a VBR, if ROM/RAM remapping is being used, copy the
         * exception vector table to RAM */
        movea.l #0, %a1                 /* Destination address */

0:      move.w  %a0@+, %a1@+
        dbf     %d0, 0b
#endif /* NO_ROMRAM_REMAP */
#endif /* USEVBR */

        /* Initialise (clear) the BSS area */
        movea.l #_bss_start, %a0        /* Starting address */
        movea.l #_bss_end, %a1          /* End address */

1:      cmpa.l  %a1, %a0                /* Check if start < end */
        bge     2f

        clr.w   %a0@+                   /* Clear word and increment start */

        bra     1b

        /* Copy initialised data from ROM to RAM */
2:      movea.l #_text_end, %a0         /* Source address */
        movea.l #_data_start, %a1       /* Destination start address */
        movea.l #_data_end, %a2         /* Destination end address */

3:      cmpa.l  %a2, %a1                /* Check if start < end */
        bge     4f

        move.w  %a0@+, %a1@+            /* Copy a word from ROM to RAM */

        bra     3b

        /* Execute hardware init hook if present */
4:      clr.l   %d0
        lea     hardware_init_hook, %a0
        cmpa.l  %d0, %a0
        beq     5f
        jsr     (%a0)

        /* Execute software init hook if present */
5:      clr.l   %d0
        lea     software_init_hook, %a0
        cmpa.l  %d0, %a0
        beq     6f
        jsr     (%a0)

        /* Jump to main() */
6:      jmp     main

        /* In a bare metal environment, main() should not return as there is
         * nowhere to resume execution from. Behaviour is undefined if this
         * happens! */

/*
 * __DefaultInterrupt handles all interrupt and exception vectors that have not
 * been overridden by the programmer.
 *
 * Unless handled more specifically, all exceptions and interrupts are masked
 * and the CPU stops executing.
 */
        .type __DefaultInterrupt, @function
        .weak __DefaultInterrupt
        .globl __DefaultInterrupt
__DefaultInterrupt:
        stop    #0x2700
        bra     .

        .end
