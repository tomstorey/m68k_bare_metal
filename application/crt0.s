    .title "crt0.s for m68k bare metal (application)"

    .extern main

    .extern _text_end
    .extern _data_start
    .extern _data_end
    .extern _bss_start
    .extern _bss_end

    .global _start

    .section text
    .align 2
_start:
    /*
     * Copy initialised data from ROM to RAM.
     */
    movea.l #_rodata_end, %a0   /* A0 is source pointer */
    movea.l #_data_start, %a1   /* A1 is destination pointer */
    movea.l #_data_end, %a2     /* A2 is end of .data */

.data_copy_loop:
    /*
     * Copy long words, post incrementing pointers, until the destination
     * pointer equals the end of the .data section.
     */
    cmpa.l  %a1, %a2            /* If no data to copy, skip */
    beq     .zeroise_bss

    move.l  (%a0)+, (%a1)+
    bra     .data_copy_loop

.zeroise_bss:
    movea.l #_bss_start, %a0    /* A0 is destination pointer */
    movea.l #_bss_end, %a1      /* A1 is end of .bss */

    cmpa.l  %a0, %a1            /* If no memory to clear, skip */
    beq     .call_main

.zeroise_bss_loop:
    /*
     * Clear long words, post incrementing pointer, until the destination
     * pointer equals the end of the .bss section.
     */
    clr.l  (%a0)+
    cmpa.l %a0, %a1
    bne    .zeroise_bss_loop

.call_main:
    /*
     * Jump to main routine.
     */
    jmp     main

    /*
     * Assume return at the end of main() is used to resume execution from
     * whence we came.
     */
