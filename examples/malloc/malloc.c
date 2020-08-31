#include <stddef.h>
#include "include/stdint.h"
#include "malloc.h"

extern uint32_t _heap_start;            /* Start address of heap */
extern uint32_t _heap_end;              /* End address of heap */

typedef struct _block_list
{
    struct _block_list *next;
    size_t size;
} block_list_t;

static block_list_t free_list;
static block_list_t *free_list_end = NULL;

#define MIN_BLOCK sizeof(block_list_t)  /* Minimum block size is the size of a
                                           block_list_t */
#define ALIGN_BYTES 2                   /* Blocks aligned to n bytes */
#define ALIGN_MASK (-1 << (ALIGN_BYTES - 1))

static void
heap_init(void)
{
    block_list_t *first_block;
    size_t heap_sz = 0;

    /* _heap_start and _heap_end are provided by the linker script */
    size_t heap_start = (size_t)&_heap_start;
    size_t heap_end = (size_t)&_heap_end;

    /* Make sure that heap starts and ends properly aligned */
    heap_end = (heap_end & ALIGN_MASK);

    if ((heap_start & ~ALIGN_MASK) != 0) {
        heap_start = (heap_start + ALIGN_BYTES) & ALIGN_MASK;
    }

    /* Heap size excludes space required for the end of free list struct */
    heap_sz = heap_end - heap_start - MIN_BLOCK;

    /* Insert the end of free list at top of heap */
    free_list_end = (void *)(heap_end - MIN_BLOCK);
    free_list_end->next = NULL;
    free_list_end->size = 0;

    /* free_list holds a pointer to the first free block which is placed at the
     * start of the heap
     */
    free_list.next = (block_list_t *)heap_start;
    free_list.size = 0;

    /*
     * In the beginning there is only a single free block, and it consumes the
     * entire heap, minus the size of the first block struct
     */
    first_block = (void *)heap_start;
    first_block->next = free_list_end;
    first_block->size = heap_sz;
}

void *
malloc(size_t want)
{
    block_list_t *this_block;
    block_list_t *prev_block;
    block_list_t *new_block;
    void *alloc = NULL;

    /* If the heap has not been initialised, do it */
    if (free_list_end == NULL) {
        heap_init();
    }

    /* Only attempt to allocate if some space has been requested */
    if (want > 0) {
        /* Must always request an additional MIN_BLOCK worth of space to hold
         * the block struct for this allocation. Also make sure the allocation
         * size is a multiple of ALIGN_BYTES.
         */
        want += MIN_BLOCK;

        if ((want & ~ALIGN_MASK) != 0) {
            want += ALIGN_BYTES;
            want &= ALIGN_MASK;
        }

        /* Loop through available blocks to find one with enough free space */
        prev_block = &free_list;
        this_block = free_list.next;

        while((this_block->size < want) && (this_block->next != NULL)) {
            prev_block = this_block;
            this_block = this_block->next;
        }

        /* If the end of the free list was not reached, allocate the space */
        if (this_block != free_list_end) {
            alloc = (void *)prev_block->next + MIN_BLOCK;

            /* Now that this block has been "allocated", adjust surrounding
             * block pointers to skip it ...
             */
            prev_block->next = this_block->next;

            /* ... but if the remaining space in this block is large enough that
             * it could be turned into another free block, do that
             */
            if ((this_block->size - want) > MIN_BLOCK) {
                /* Insert new block entry after allocation */
                new_block = (void *)this_block + want;
                new_block->next = free_list_end;
                new_block->size = (this_block->size - want);

                /* Adjust the pointer of the previous block to point to this
                 * new block */
                prev_block->next = new_block;

                /* Adjust the size of the allocation to the size allocated. If
                 * its not big enough to split into two, its size will remain
                 * larger than the requested size.
                 */
                this_block->size = want;
            }

            /* Null out the next pointer for the allocated block */
            this_block->next = NULL;
        }
    }

    return alloc;
}

void
free(void *alloc)
{
    block_list_t *prev_block;
    block_list_t *next_block;
    block_list_t *free_block;
    uint8_t *block;

    if (alloc != NULL) {
        /* The alloc pointer is to the start of the allocated data itself,
         * therefore need to subtract MIN_BLOCK in order to point to the block
         * struct that preceeds the data.
         */
        alloc -= MIN_BLOCK;
        free_block = (void *)alloc;

        if (free_block->next == NULL) {
            /* Loop through the free list to find the first next block with an
             * address that is higher than free_block
             */
            prev_block = &free_list;

            while(prev_block->next < free_block) {
                prev_block = prev_block->next;
            }

            next_block = prev_block->next;

            /* There are now several things that can happen:
             *
             * 1. The free block is not adjacent to either the lower or upper
             *    blocks, and therefore will be freed as an individual block on
             *    its own
             * 2. The free block is adjacent to either the upper or lower block
             *    and will be merged with either of those blocks
             * 3. The free block is adjacent to both the upper and lower blocks
             *    and these will all be merged into one single larger block
             */
            block = (uint8_t *)free_block;

            if ((block + free_block->size) == (uint8_t *)next_block) {
                /* Merge the freed block + upper block */
                prev_block->next = free_block;
                free_block->next = next_block->next;
                free_block->size += next_block->size;
            } else {
                /* Insert freed block between upper and lower blocks */
                prev_block->next = free_block;
                free_block->next = next_block;
            }

            block = (uint8_t *)prev_block;

            if ((block + prev_block->size) == (uint8_t *)free_block) {
                /* Merge the lower block + freed block */
                prev_block->next = free_block->next;
                prev_block->size += free_block->size;
            }
        }
    }
}
