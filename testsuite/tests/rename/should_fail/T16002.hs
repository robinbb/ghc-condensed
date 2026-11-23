{-# LANGUAGE TypeFamilies #-}
module T16002 where

import Data.Kind (Type)

data A
type family B (x :: Type) :: Type where
  A x = x
