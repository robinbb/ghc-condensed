.. _binary-literals:

Binary integer literals
-----------------------

Haskell 2010 and Haskell 98 allow for integer literals to be given in
decimal, octal (prefixed by ``0o`` or ``0O``), or hexadecimal notation
(prefixed by ``0x`` or ``0X``).

GHC also accepts integer literals in binary notation with the prefix ``0b``
or ``0B``. For instance, the binary integer literal ``0b11001001`` is
desugared into ``fromInteger 201``.
