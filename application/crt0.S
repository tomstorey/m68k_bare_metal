        .title "crt0.S for m68k bare metal - application"

        /* A bunch of variables supplied by the linker */
        .extern _bss_start
        .extern _bss_end
        .extern _rodata_end
        .extern _data_start
        .extern _data_end
        .extern main

        .section .text
        .align 2

        .type _start, @function
        .globl _start
_start:
        /* Initialise (clear) the BSS area */
        movea.l #_bss_start, %a0        /* Starting address */
        movea.l #_bss_end, %a1          /* End address */

0:      cmpa.l  %a1, %a0                /* Check if start < end */
        bge     1f

        clr.w   %a0@+                   /* Clear word and increment start */

        bra     0b

        /* Copy initialised data from ROM to RAM */
1:      movea.l #_rodata_end, %a0       /* Source address */
        movea.l #_data_start, %a1       /* Destination start address */
        movea.l #_data_end, %a2         /* Destination end address */

2:      cmpa.l  %a2, %a1                /* Check if start < end */
        bge     3f

        move.w  %a0@+, %a1@+            /* Copy a word from ROM to RAM */

        bra     2b

        /* Jump to main() */
3:      jmp     main

        /* It is possible that main() may return in an application context, but
         * this needs to be appropriately managed by the calling code. */

        .end
