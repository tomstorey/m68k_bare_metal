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
        /* Initialise (clear) the BSS area */
        lea     %pc@(_bss_start), %a0   /* Starting address */
        lea     %pc@(_bss_end), %a1     /* End address */

0:      cmpa.l  %a1, %a0                /* Check if start < end */
        bge     1f

        clr.w   %a0@+                   /* Clear word and increment start */

        bra     0b

        /* The application is compiled as if it were located at address 0, therefore all entries in
         * the Global Offset Table will be relative to address 0. Its probably unlikely that the
         * binary will run from address 0 in a real system, therefore the GOT needs to be adjusted
         * to add the base address where the application has been loaded to all of its entries. */
1:      lea     %pc@(_start), %a0       /* Base address where the application has been loaded */
        move.l  %a0, %d0
        movea.l #_got_start, %a1        /* Start of the GOT, relative to address 0 */
        movea.l #_got_end, %a2          /* End of the GOT, relative to address 0 */
        
        /* A1 and A2 will be relative addresses from the start of the applications binary image,
         * which at compile time is assumed to be address 0. We need to add the base address where
         * the image was loaded to get the physical address in memory where the GOT exists. */
        adda.l  %d0, %a1
        adda.l  %d0, %a2

        /* Now loop through the GOT entries and add the base address */
2:      cmpa.l  %a2, %a1                /* Check if start < end */
        bge     3f

        add.l   %d0, %a1@
        addq.l  #4, %a1

        bra     2b

        /* Setup A5 as the GOT pointer */
3:      movea.l #_got_start, %a5
        adda.l  %d0, %a5

        /* Jump to main() - main() will have a GOT entry, but we dont know which one it is, so work
         * out its physical address manually */
4:      movea.l #main, %a0
        adda.l  %d0, %a0
        jmp     %a0@

        /* It is possible that main() may return in an application context, but
         * this needs to be appropriately managed by the calling code. */

        .end
