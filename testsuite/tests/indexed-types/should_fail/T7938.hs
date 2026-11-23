{-# LANGUAGE TypeFamilies,
             FlexibleInstances #-}

module T7938 where

import Data.Kind (Type)

data KProxy (a :: Type) = KP

class Foo (a :: k1) (b :: k2) where
  type Bar a

instance Foo (a :: k1) (b :: k2) where
  type forall k2 . Bar a = (KP :: KProxy k2)
