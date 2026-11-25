{-# LANGUAGE ConstraintKinds #-}

module SAKS_Fail016 where

import Data.Kind (Constraint)

data T (a :: k)

type C :: forall k. k -> Constraint
class C a where
  getC :: forall. T (a :: k)   -- 'k' is not brought into scope by the standalone kind signature
