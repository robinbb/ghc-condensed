.. _traditional-record-syntax:

Traditional record syntax
-------------------------

Traditional record syntax, such as ``C {f = x}``, is always available: a
record datatype may be defined, and record syntax used in expressions and
patterns, in every language edition.  For example:

.. code-block:: haskell

     data T = MkT { foo :: Int }  -- record datatype definition

     x = MkT { foo = 3 }          -- construction

     y = x { foo = 3 }            -- update

     f (MkT { foo = i }) = i      -- pattern matching

If you wish to suppress field selector functions, use the
:extension:`NoFieldSelectors` extension.
