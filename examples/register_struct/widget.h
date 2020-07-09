#include "stdint.h"

#define WIDGETCTRL (*(volatile uint8_t *)(0x800016))
/*                  ^ ^                   ^
 *                  | |                   Absolute address of register
 *                  | Volatile pointer to an 8 bit unsigned quantity
 *                  Dereference pointer to access its value
 */

typedef union {
    struct {
        uint8_t :2;         /* 2 unused bits */
        uint8_t INT:1;      /* INT is a single bit option */
        uint8_t MODE:4;     /* MODE is a bit field of 4 bits wide */
        uint8_t EN:1;       /* The LSb is the last member of the struct */
    };
    struct {
        uint8_t :3;         /* Skip the first 2 bits */
        uint8_t MODE3:1;    /* Break the MODE bit field into individual bits */
        uint8_t MODE2:1;
        uint8_t MODE1:1;
        uint8_t MODE0:1;
        uint8_t :1;
    };
} __WIDGETCTRLbits_t;

#define WIDGETCTRLbits (*(volatile __WIDGETCTRLbits_t *)(0x800016))
