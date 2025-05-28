        .title "crt0.S for m68k bare metal - Position Independent Executable application"

        /* A bunch of variables supplied by the linker */
        .extern _bss_start
        .extern _bss_end
        .extern _got_start
        .extern _got_end
        .extern main

        .section .text
        .align 2

        .type _start, @function
        .globl _start
_start:
        lea     %pc@(_start), %a0       /* Gets the physical ddress of the application code */
        move.l  %a0, %d5                /* Keep it for later */

        /* Initialise (clear) the BSS area
         *
         * The application is compiled as if it were physically located at address 0, therefore all
         * labels etc are relative to address 0. Its unlikely that the application will actually run
         * from address 0, so the addresses of these labels have to be fixed up to represent their
         * physical locations. This is done by adding in D5 as obtained above. */
        movea.l #_bss_start, %a0        /* Start address of BSS */
        movea.l #_bss_end, %a1          /* End address of BSS */

        adda.l  %d5, %a0
        adda.l  %d5, %a1

0:      cmpa.l  %a1, %a0                /* Check if start < end */
        bge     1f

        clr.w   %a0@+                   /* Clear word and increment start */

        bra     0b

        /* As with the BSS section, the labels for the Global Offset Table need to be fixed up to
         * represent their physical locations. */
1:      movea.l #_got_start, %a0        /* Start address of the GOT */
        movea.l #_got_end, %a1          /* End address of the GOT */
        
        adda.l  %d5, %a0
        adda.l  %d5, %a1

2:      cmpa.l  %a1, %a0                /* Check if start < end */
        bge     3f

        add.l   %d5, %a0@+

        bra     2b

        /* Set up A5 as the GOT pointer */
3:      movea.l #_got_start, %a5
        adda.l  %d5, %a5

        /* Jump to main() - main() will have a GOT entry, but we dont know which one it is, so
         * figure it out ourselves */
4:      movea.l #main, %a0
        adda.l  %d5, %a0
        jmp     %a0@

        /* It is possible that main() may return in an application context, but
         * this needs to be appropriately managed by the calling code. */

        .end
