.. _flexible-contexts:

Loosening restrictions on class contexts
----------------------------------------

Haskell 98 requires the type-class constraints, anywhere they appear, to
have the form *(class type-variable)* or *(class (type-variable type1 type2
... typen))*. GHC lifts that restriction: these type signatures are
perfectly okay::

      g :: Eq [a] => ...
      g :: Ord (T a ()) => ...

The same holds for the context of a class, an instance or a data
constructor. The restriction on the head of an instance declaration is a
separate one; see :extension:`FlexibleInstances`.
