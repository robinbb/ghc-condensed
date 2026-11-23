{-# LANGUAGE GADTs                      #-}

module PolyKinds02 where

import Data.Kind (Type)

data Nat = Ze | Su Nat

data Vec :: Type -> Nat -> Type where
  VNil  :: Vec a Ze
  VCons :: a -> Vec a n -> Vec a (Su n)

vec :: Vec Nat Nat -- Kind error
vec = vec
