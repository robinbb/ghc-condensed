{-# LANGUAGE TypeFamilies #-}

module T11361a where

import Data.Kind (Type)

class C a where
  type F (a :: k) :: Type
  type F (x :: Type) = x    -- Not right!
