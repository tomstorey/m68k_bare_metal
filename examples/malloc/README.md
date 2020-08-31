# `malloc` and `free`
This example contains a simple `malloc` and `free` which can be used for dynamic memory allocation.

## `malloc`
This implementation of `malloc` works the same way as most other implementations of `malloc`. That is, you attempt to allocate *n* bytes of storage, and if the operation is successful a pointer to the beginning of the allocated space is returned. If the allocation fails, a null pointer is returned.

The following is an example of how to use `malloc` to allocate some space for a 32 bit unsigned integer, and then increment that integer:

```c
#include <stddef.h>
#include "stdint.h"
#include "malloc.h"

int
main(void)
{
    uint32_t *a = (uint32_t *)malloc(sizeof(uint32_t));
    
    if (a == NULL) {
    	/* Allocation did not succeed, handle error */
    }
    
    (*a)++;
}
```

`malloc` does not initialise the allocated space, so the user must initialise it appropriately for the application at hand.

## `free`
`free` is used to return the space used by an allocation to the heap, after which it can be allocated by subsequent calls to `malloc`.

This implementation of `free` implements some basic fragmentation management capabilities. When a block is freed, `free` will attempt to merge it with surrounding free blocks, ensuring that all free blocks are always maintained as large as possible, and also minimising the overall count of free blocks.

The following is an example of how to use `free`:

```c
#include <stddef.h>
#include "stdint.h"
#include "malloc.h"

int
main(void)
{
    uint32_t *a = (uint32_t *)malloc(sizeof(uint32_t));
    
    if (a == NULL) {
    	/* Allocation did not succeed, handle error */
    }
    
    (*a)++;
    
    free(a);
}
```

`free` does not clear the contents of the freed block, so the user must do this themselves if a freed block of memory could potentially leak sensitive information via a subsequent allocation.

## Heap Initialisation
This implementation of `malloc` handles heap initialisation automatically. The first time you call `malloc`, the pointer indicating the end of the free list is checked, and if it is null, `heap_init` is called to initialise the free list and make the heap available for dynamic allocation. The call to `malloc` then proceeds as normal.

Two variables are supplied by the linker script which provide the start and end addresses of the space that is assigned to the heap. The heap is considered to be all space between the end of the `.bss` section, and the lowest address allocated to the stack.
