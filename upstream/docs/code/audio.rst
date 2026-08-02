Audio
=====

The hardware abstraction layer only supports a minimal audio interface. It is only possible to play
a single short tone. Any platform that wants to support audio should implement this function.

Functions
---------

.. doxygenfile:: hal/audio.h

Example
-------

To play the note C with frequency 277.183Hz, you would call

.. code-block:: C

   audioTone(277183);

Note that frequencies are in mHz.
