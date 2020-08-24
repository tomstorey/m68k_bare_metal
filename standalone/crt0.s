    .title "crt0.s for m68k bare metal"

    .extern main
    .weak hardware_init_hook
    .weak software_init_hook

    .extern __ram_base
    .extern __ram_sz

    .extern _text_end
    .extern _data_start
    .extern _data_end
    .extern _bss_start
    .extern _bss_end

    .global _start
    .global __DefaultInterrupt

    .section text
    .align 2
_start:
    clr.l   %d0                 /* For zero compares */
    move.l  #0x55555555, %d2    /* Mem test subtract value */

    /*
     * Memory test
     */
    movea.l #__ram_base, %a1    /* A1 is RAM base address */
    movea.l #__ram_sz, %a2      /* A2 is RAM size */

.next_memtest:
    /*
     * Walking ones
     *
     * Start with 0x00000001 in D1, and left shift until zero.
     */
    move.l  %a1, %a0            /* Addr to test into A0 */
    move.l  #1, %d1             /* Test pattern into D1 */

.next_walk_one:
    move.l  %d1, (%a0)
    cmp.l   (%a0), %d1
    bne     .memtest_fail
    lsl.l   #1, %d1
    bne     .next_walk_one

    /*
     * Value test
     *
     * Initially load all ones, then subtract 0x55555555 on each pass until the
     * pattern reaches zero.
     *
     * This cycles through the following patterns:
     *
     * 0xffffffff
     * 0xaaaaaaaa
     * 0x55555555
     * 0x00000000
     *
     * As the last pattern to be written is zero, this effectively initialises
     * all RAM locations to zero, and as such the .bss section does not need to
     * be cleared as a separate step.
     */
    move.l  #0xffffffff, %d1

.next_val:
    move.l  %d1, (%a0)
    cmp.l   (%a0), %d1
    bne     .memtest_fail

    cmp.l   %d0, %d1            /* If last pattern was zero, next mem addr */
    beq     .memtest_loop

    sub.l   %d2, %d1
    bra     .next_val

.memtest_loop:
    addq.l  #4, %a1             /* Increment addr pointer */
    subq.l  #4, %a2             /* Decrement amount of memory left to test */
    move.l  %a2, %d3            /* SUBQ on address reg doesnt affect flags */
    bne     .next_memtest       /* If A2 is not zero, continue testing */
    bra     .data_copy          /* Otherwise memory testing is complete */

.memtest_fail:
    bra     .memtest_fail       /* Halt on failure */

.data_copy:
    /*
     * Copy initialised data from ROM to RAM.
     */
    movea.l #_text_end, %a0     /* A0 is source pointer */
    movea.l #_data_start, %a1   /* A1 is destination pointer */
    movea.l #_data_end, %a2     /* A2 is end of .data */

.data_copy_loop:
    /*
     * Copy long words, post incrementing pointers, until the destination
     * pointer equals the end of the .data section.
     */
    cmpa.l  %a1, %a2            /* If no data to copy, skip */
    beq     .hard_init

    move.l  (%a0)+, (%a1)+
    bra     .data_copy_loop

.hard_init:
    /*
     * Execute hardware initialisation hook if present.
     */
    lea     hardware_init_hook, %a0
    cmpa.l  %d0, %a0
    beq     .soft_init
    jsr     (%a0)

.soft_init:
    /*
     * Execute software initialisation hook if present.
     */
    lea     software_init_hook, %a0
    cmpa.l  %d0, %a0
    beq     .call_main
    jsr     (%a0)

.call_main:
    /*
     * Jump to main routine.
     */
    jmp     main

    reset                       /* Reset on return from main() */

/*
 * __DefaultInterrupt handles all interrupt and exception vectors that have not
 * been overridden by the programmer.
 *
 * Unless handled more specifically, all exceptions and interrupts cause the
 * processor to reset.
 */
__DefaultInterrupt:
    reset
