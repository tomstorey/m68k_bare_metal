        .title "crt0.S for m68k bare metal - PC relative application"

        /* A bunch of variables supplied by the linker */
        .extern _bss_start
        .extern _bss_end
        .extern main

        .section .text
        .align 2

        .type _start, @function
        .globl _start
_start:
        /* Initialise (clear) the BSS area */
        lea     %pc@(_bss_start), %a0   /* Starting address */
        lea     %pc@(_bss_end), %a1     /* End address */

0:      cmpa.l  %a1, %a0                /* Check if start < end */
        bge     1f

        clr.w   %a0@+                   /* Clear word and increment start */

        bra     0b
        
        /* Jump to main() */
1:      lea     %pc@(main), %a0
        jmp     %a0@

        /* It is possible that main() may return in an application context, but
         * this needs to be appropriately managed by the calling code. */

        .end
