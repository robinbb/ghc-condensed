.. _promotion:

Datatype promotion
==================

This section describes *data type promotion*, a feature of the kind
system that complements kind polymorphism. It is described in more detail
in the paper `Giving Haskell a Promotion
<https://dreixel.net/research/pdf/ghp.pdf>`__, which appeared at TLDI
2012.
See also :extension:`TypeData` for a more fine-grained alternative.

Motivation
----------

Standard Haskell has a rich type language. Types classify terms and
serve to avoid many common programming mistakes. The kind language,
however, is relatively simple, distinguishing only regular types (kind
``Type``) and type constructors (e.g. kind ``Type -> Type -> Type``).
In particular when using advanced type
system features, such as type families (:ref:`type-families`) or GADTs
(:ref:`gadt`), this simple kind system is insufficient, and fails to
prevent simple errors. Consider the example of type-level natural
numbers, and length-indexed vectors: ::

    data Ze
    data Su n

    data Vec :: Type -> Type -> Type where
      Nil  :: Vec a Ze
      Cons :: a -> Vec a n -> Vec a (Su n)

The kind of ``Vec`` is ``Type -> Type -> Type``. This means that, e.g.,
``Vec Int Char`` is a well-kinded type, even though this is not what we
intend when defining length-indexed vectors.

With promotion, the example above can be rewritten to: ::

    data Nat = Ze | Su Nat

    data Vec :: Type -> Nat -> Type where
      Nil  :: Vec a Ze
      Cons :: a -> Vec a n -> Vec a (Su n)

With the improved kind of ``Vec``, things like ``Vec Int Char`` are now
ill-kinded, and GHC will report an error.

Overview
--------

GHC automatically promotes every datatype
to be a kind and its (value) constructors to be type constructors. The
following types ::

    data Nat = Zero | Succ Nat

    data List a = Nil | Cons a (List a)

    data Pair a b = MkPair a b

    data Sum a b = L a | R b

give rise to the following kinds and type constructors: ::

    Nat :: Type
    Zero :: Nat
    Succ :: Nat -> Nat

    List :: Type -> Type
    Nil  :: forall k. List k
    Cons :: forall k. k -> List k -> List k

    Pair  :: Type -> Type -> Type
    MkPair :: forall k1 k2. k1 -> k2 -> Pair k1 k2

    Sum :: Type -> Type -> Type
    L :: k1 -> Sum k1 k2
    R :: k2 -> Sum k1 k2

Virtually all data constructors, even those with rich kinds, can be promoted.
There are only a couple of exceptions to this rule:

-  Data family instance constructors cannot be promoted at the moment. GHC's
   type theory just isn’t up to the task of promoting data families, which
   requires full dependent types.

-  Data constructors with contexts cannot be promoted. For example::

     data Foo :: Type -> Type where
       MkFoo :: Show a => Foo a    -- not promotable

.. _promotion-syntax:

Distinguishing between types and constructors
---------------------------------------------

Consider ::

    data P = MkP    -- 1

    data Prom = P   -- 2

The name ``P`` on the type level will refer to the type ``P`` (which has
a constructor ``MkP``) rather than the promoted data constructor
``P`` of kind ``Prom``. To refer to the latter, prefix it with a
single quote mark: ``'P``.

This syntax can be used even if there is no ambiguity (i.e.
there's no type ``P`` in scope).

GHC supports :ghc-flag:`-Wunticked-promoted-constructors` that warns
whenever a promoted data constructor is written without a quote mark.
As of GHC 9.4, this warning is no longer enabled by :ghc-flag:`-Wall`;
we no longer recommend quote marks as a preferred default
(see :ghc-ticket:`20531`).

Just as in the case of Template Haskell (:ref:`th-syntax`), GHC gets
confused if you put a quote mark before a data constructor whose second
character is a quote mark. In this case, just put a space between the
promotion quote and the data constructor: ::

  data T = A'
  type S = 'A'   -- ERROR: looks like a character
  type R = ' A'  -- OK: promoted `A'`

Type-level literals
-------------------

Numeric and string literals can be used at the type level. For more
information, see :ref:`type-level-literals`.

.. _promoted-lists-and-tuples:

Promoted list and tuple types
-----------------------------

Haskell's list and tuple types are natively promoted to kinds, and enjoy
the same convenient syntax at the type level, albeit prefixed with a
quote: ::

    data HList :: [Type] -> Type where
      HNil  :: HList '[]
      HCons :: a -> HList t -> HList (a ': t)

    data Tuple :: (Type,Type) -> Type where
      Tuple :: a -> b -> Tuple '(a,b)

    foo0 :: HList '[]
    foo0 = HNil

    foo1 :: HList '[Int]
    foo1 = HCons (3::Int) HNil

    foo2 :: HList [Int, Bool]
    foo2 = ...

For type-level lists of *two or more elements*, such as the signature of
``foo2`` above, the quote may be omitted because the meaning is unambiguous. But
for lists of one or zero elements (as in ``foo0`` and ``foo1``), the quote is
required, because the types ``[]`` and ``[Int]`` have existing meanings in
Haskell.

.. note::
    The declaration for ``HCons`` also requires :extension:`TypeOperators`
    because of infix type operator ``(':)``


.. _promotion-existentials:

Promoting existential data constructors
---------------------------------------

Note that we do promote existential data constructors that are otherwise
suitable. For example, consider the following: ::

    data Ex :: Type where
      MkEx :: forall a. a -> Ex

Both the type ``Ex`` and the data constructor ``MkEx`` get promoted,
with the polymorphic kind ``'MkEx :: forall k. k -> Ex``. Somewhat
surprisingly, you can write a type family to extract the member of a
type-level existential: ::

    type family UnEx (ex :: Ex) :: k
    type instance UnEx (MkEx x) = x

At first blush, ``UnEx`` seems poorly-kinded. The return kind ``k`` is
not mentioned in the arguments, and thus it would seem that an instance
would have to return a member of ``k`` *for any* ``k``. However, this is
not the case. The type family ``UnEx`` is a kind-indexed type family.
The return kind ``k`` is an implicit parameter to ``UnEx``. The
elaborated definitions are as follows (where implicit parameters are
denoted by braces): ::

    type family UnEx {k :: Type} (ex :: Ex) :: k
    type instance UnEx {k} (MkEx @k x) = x

Thus, the instance triggers only when the implicit parameter to ``UnEx``
matches the implicit parameter to ``MkEx``. Because ``k`` is actually a
parameter to ``UnEx``, the kind is not escaping the existential, and the
above code is valid.

See also :ghc-ticket:`7347`.

Unique syntax for type-level lists and tuples
=============================================

.. extension:: ListTuplePuns
    :shortdesc: Enable punning for list, tuple and sum types.

    :since: 9.10.1

    Accept bracket syntax to denote type constructors, using single quotes to
    disambiguate data constructors.

The previously defined mechanism for specifying data constructors with bracket
syntax and single quotes is governed by this extension, which is enabled by
default.

With ``NoListTuplePuns``, brackets are unambiguously parsed as data
constructors, while the single quote is not accepted as a prefix for them
anymore.
Type constructors cannot be expressed with brackets anymore; instead, new
data type declarations in regular syntax have been added to ``ghc-prim``: ::

    data List a = [] | a : List a
    data Unit = ()
    data Tuple2 a b = (a, b)
    data Tuple2# a b = (# a, b #)
    data Sum2# a b = (# a | #) | (# | b #)
    class (a, b) => CTuple2 a b
    instance (c1, c2) => CTuple2 c1 c2

`CTuple2` is a constraint tuple, which historically only concerns declarations
like: ::

    type C = (Eq Int, Ord String)

These are distinct from the usual specification of multiple constraints on
functions or instances with parentheses, since those are treated specially by
GHC.

When the extension is disabled, any occurrence of special syntax in types will
be treated as the data constructor, so a type of ``(Int, String)`` has kind
``Tuple2 Type Type``, corresponding to the type ``'(Int, String)`` with kind
``(Type, Type)`` when ``ListTuplePuns`` is enabled.

The explicit disambiguation syntax using single quotes is invalid syntax when
the extension is disabled.

The earlier example would need to be rewritten like this: ::

    data HList :: List Type -> Type where
      HNil  :: HList []
      HCons :: a -> HList t -> HList (a : t)

    data Tuple :: Tuple2 Type Type -> Type where
      Tuple :: a -> b -> Tuple (a, b)

    foo0 :: HList []
    foo0 = HNil

    foo1 :: HList [Int]
    foo1 = HCons (3 :: Int) HNil

    foo2 :: HList [Int, Bool]
    foo2 = ...

Constraint tuples may be mixed with conventional syntax: ::

    f ::
      Monad m =>
      CTuple2 (Monad m) (Monad m) =>
      (Monad m, CTuple2 (Monad m) (Monad m)) =>
      m Int
    f = pure 5

The new type constructors are exported only from the library
``ghc-experimental``, by the modules ``Data.Tuple.Experimental``,
``Data.Sum.Experimental`` and ``Prelude.Experimental``.

Please refer to `GHC Proposal #475 <https://github.com/ghc-proposals/ghc-proposals/blob/master/proposals/0475-tuple-syntax.rst>`__ for the full specification of effects and interactions.
