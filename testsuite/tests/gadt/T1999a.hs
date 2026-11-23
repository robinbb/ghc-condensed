{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE GADTs #-}
-- #1999

module ShouldCompile where


import Data.Kind (Type)
-- The kinds are pinned: with kind-polymorphic indices the desugarer
-- produces a coercion that fails Core Lint.
data EqTypes (a :: Type) (b :: Type) where
  EqConstr :: EqTypes a b -> EqTypes (s a) (s b)

eqUnConstr :: EqTypes (s a) (s b) -> EqTypes a b
eqUnConstr (EqConstr eq) = eq