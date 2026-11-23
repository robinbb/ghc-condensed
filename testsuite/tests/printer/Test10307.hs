{-# LANGUAGE TypeFamilies #-}
module Test10307 where

import Data.Kind (Type)

class Foldable t where
  type FoldableConstraint t x :: Type
  type FoldableConstraint t x = ()
