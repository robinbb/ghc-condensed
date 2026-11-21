.. _multi-param-type-classes:

Multi-parameter type classes
============================

A type class may have any number of parameters, including none. The
Haskell Report allows exactly one; GHC lifts that restriction in every
language mode, and the ``MultiParamTypeClasses`` and
``NullaryTypeClasses`` extensions that once governed it no longer exist.
For example: ::

      class Collection c a where
          union :: c a -> c a -> c a
          ...etc.

.. _nullary-type-classes:

Nullary type classes
--------------------

Since a nullary (no parameter) type class has no parameters, there can be
at most one instance of it. A nullary type class might be used to
document some assumption in a type signature (such as reliance on the
Riemann hypothesis) or add some globally configurable settings in a
program. For example, ::

      class RiemannHypothesis where
        assumeRH :: a -> a

      -- Deterministic version of the Miller test
      -- correctness depends on the generalised Riemann hypothesis
      isPrime :: RiemannHypothesis => Integer -> Bool
      isPrime n = assumeRH (...)

The type signature of ``isPrime`` informs users that its correctness
depends on an unproven conjecture. If the function is used, the user has
to acknowledge the dependence with: ::

      instance RiemannHypothesis where
        assumeRH = id
