{-# LANGUAGE FlexibleContexts, TypeFamilies #-}
module T8030 where

import Data.Kind (Type)

-- The types of op1 and op2 are both ambiguous
-- and should be reported as such

class C (a :: k) where
  type Pr a :: Type
  op1 :: Pr a
  op2 :: Pr a -> Pr a -> Pr a

