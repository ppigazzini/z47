TAM
===

Most operations use various registers and flags to determine their output. Some operations
use additional input that must be entered by the user after selecting the operation. These
use the *transient alpha mode* abbreviated to TAM. The processing of this input whilst in
TAM mode and its subsequent evaluation is handled by the functions in this module, along with
the relevant user interface elements.

State and functions
-------------------

.. rubric:: State

.. doxygenstruct:: tamState_t
   :members:

.. doxygenvariable:: tam

.. doxygenvariable:: tamBuffer

.. doxygenfile:: ui/tam.h

Example
-------

Supposing a user enters the following command: ``STO 01``. Here is the sequence of events for
the TAM module.

The ``STO`` command is entered which is detected as requiring TAM

.. code-block:: C

   tamEnterMode(ITM_STO);

This updates the ``tamBuffer`` so it now contains the text ``STO __`` and sets ``tam.mode`` to
be non-zero. The calculator returns to waiting for input. The ``0`` key is pressed.

.. code-block:: C

   tamProcessInput(ITM_0);

``tamBuffer`` is updated to contain ``STO 0_`` but TAM input is not complete so ``tam.mode`` is
still set and the store function has yet to be called. The calculator again returns to waiting
for input. The ``1`` key is pressed.

.. code-block:: C

   tamProcessInput(ITM_1);

This completes the necessary input so the function associated with ``ITM_STO`` (``fnStore``) is
called with the parameter value ``1``. TAM is now completed so ``tam.mode`` is now ``0``.
