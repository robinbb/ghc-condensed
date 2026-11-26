.. _duplicate-record-fields:

Duplicate record fields
-----------------------

Multiple datatypes in a single module may be declared using the same field
names. For example, this is permitted: ::

    module M where
      data S = MkS { x :: Int }
      data T = MkT { x :: Bool }

Uses of fields that are always unambiguous because they mention the constructor,
including construction and pattern-matching, may freely use duplicated field
names. For example, the following are permitted: ::

    s = MkS { x = 3 }

    f (MkT { x = b }) = b

While multiple fields may share a name in a single module, a field and a normal
value binding may not have the same name.  For that, use
:extension:`NoFieldSelectors`.

Selector names have to be entirely unambiguous (under the usual name resolution rules),
while for record updates, there must be at most one datatype that has all the field names being updated.

Import and export of record fields
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An ambiguous field must be exported as part of its datatype, rather than at
the top level. For example, the following is legal: ::

    module M
      ( S(x)
      , T(..)
      ) where

    data S = MkS { x :: Int }

    data T = MkT { x :: Bool }

However, this would not be permitted, because ``x`` is ambiguous: ::

    module M (x) where ...

For ``import`` statements, it is possible to import multiple fields with the
same name, as well as importing individual fields as part of their datatypes.
For example, the following imports are allowed: ::

    import M (S(x))        -- imports the type S and the 'x' field of S (but not the field of T)
    import M (x)           -- imports both 'x' fields
    import M hiding (S(x)) -- imports everything except the type S and its 'x' field
    import M hiding (x)    -- imports everything except the two 'x' fields
