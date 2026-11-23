{-# LANGUAGE TypeFamilies #-}

module Exp (C, C(type T), T, foo, S)
where

import Data.Kind (Type)

class C a where
  data T a :: Type
  foo :: a -> a

data family S a b :: Type
