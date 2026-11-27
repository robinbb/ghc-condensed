.. _monomorphism:

The monomorphism restriction
----------------------------

GHC does not implement the monomorphism restriction of `Section 4.5.5
<https://www.haskell.org/onlinereport/haskell2010/haskellch4.html#x10-930004.5.5>`__
of the Haskell Report, in any language edition. A binding without a type
signature is generalised over its class constraints whatever its shape:
``plus = (+)`` has type ``Num a => a -> a -> a`` and may be used at
several types, and a pattern binding is generalised in the same way.
GHCi has behaved like this since GHC 7.8.1. A pattern binding is
generalised as a group, so one whose variables carry independent class
constraints, such as ``(lo, hi) = (minBound, maxBound)``, has an
ambiguous type and needs a type signature for each variable.

One consequence is that an overloaded constant without a signature is a
function of its class dictionary, so it is recomputed at every use rather
than shared. To keep such a binding monomorphic and shared, give it a
type signature::

    table :: [Integer]
    table = map expensive [1 .. 1000]

The type of ``table`` is then fixed and its value is computed once.

The ``main`` function of the main module is the one exception. The Report
fixes its type at ``IO t``, and GHC infers an unannotated ``main`` at that
type rather than generalising it over its monad (as if it were written with
the partial signature ``main :: IO _``), so a ``main`` built from ``printf``
is not ambiguous and a long ``do`` block is typed at ``IO`` directly. A
``main`` with a type signature, a ``main`` in another module and a local
binding called ``main`` are generalised like any other binding.
