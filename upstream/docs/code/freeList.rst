Free list allocator
===================

Different memory allocators have different trade-offs. The free list allocator used here
has a fixed total number of lists of free blocks (rather than a linked list or tree).
Because of this it will be fast, but will not cope with significant memory fragmentation
compared to ``malloc``. It also has a very small minimum allocation compared to ``malloc``.
Since this allocator is used with known fixed sizes, the size allocated isn't stored so
it must be passed into the ``freeListFree`` function (and ``freeListRealloc``).

This allocator shouldn't be used directly as there are wrapper functions that keep track
of useful debugging information.

Functions
---------

.. doxygenfile:: core/freeList.h

Example
-------

As with any allocator, allocated memory must be freed.

.. code-block:: C

   uint16_t *myMemory = (uint16_t *)freeListAlloc(TO_BLOCKS(8*2));
   ...
   uint16_t *newMemory = (uint16_t *)freeListRealloc(myMemory, TO_BLOCKS(8*2), TO_BLOCKS(16*2));
   ...
   freeListFree(myMemory, TO_BLOCKS(16*2));

