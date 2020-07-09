#include "stdint.h"
#include "widget.h"

int
main(void)
{
    /*
     * Example 1
     *
     * Using the preprocessor directive WIDGETCTRL you can directly read and
     * write the register address as an 8 bit quanitity (or larger if defined
     * appropriately).
     */
    uint8_t widget_cfg_read = WIDGETCTRL;

    WIDGETCTRL = 0x12;

    /*
     * Example 2a
     *
     * Using the preprocessor directive WIDGETCTRLbits and the associated
     * typedef'd union, you can access individual bits and bitfields of the
     * register independently.
     */
    WIDGETCTRLbits.INT = 0;     /* Widget should not generate interrupts */
    WIDGETCTRLbits.MODE = 9;    /* Widget operating mode 9 */
    WIDGETCTRLbits.EN = 1;      /* Enable the Widget */

    uint8_t widget_mode = WIDGETCTRLbits.MODE;

    /*
     * Example 2b
     *
     * It is also possible to modify an individual bit of a larger bitfield if
     * you create the appropriate corresponding struct in the union.
     */
    WIDGETCTRLbits.MODE0 = 0;   /* Widget operating mode should really be 8 */

    /*
     * Example 3
     *
     * Example 2 results in read-modify-write operations being performed on the
     * Widget control register. Some peripherals may not permit these kinds of
     * operations for various reasons, such as:
     *
     *  ) Each address a peripheral responds to is shared with multiple
     *    registers internally, e.g. writing a control register and reading a
     *    status register at the same address - in this case, read-modify-write
     *    causes the value of the status register to be read, modified as per
     *    your code, and then written back to the control register, which is
     *    very likely not the intended behaviour
     *  ) When writing a register, subsequent bytes may be considered data to
     *    load into some other registers, so the first modification changes the
     *    control register, but then subsequent changes will be written to other
     *    registers within the device
     *  ) A register may simply be write only
     *
     * For these reasons and perhaps others dependent on the device in question,
     * it may be necessary to write the entire contents of a register in one
     * operation. This can be performed in the following way.
     */
    __WIDGETCTRLbits_t widget_cfg;

    widget_cfg.INT = 0;         /* Widget should not generate interrupts */
    widget_cfg.MODE = 9;        /* Widget operating mode 9 */
    widget_cfg.EN = 1;          /* Enable the Widget */

    widget_cfg.MODE0 = 0;       /* Widget operating mode should really be 8 */

    WIDGETCTRL = (*(uint8_t *)&widget_cfg);
}
