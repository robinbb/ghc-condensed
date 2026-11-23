{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
module T14179 where

import Data.Kind (Type)

data family   Foo1 a
data instance Foo1 a
data instance Foo1 a

data family   Foo2 :: k -> Type
data instance Foo2 :: Type -> Type
data instance Foo2 :: Type -> Type

data family Foo3 a
data instance Foo3 [a] where
  Foo3a :: Foo3 [Int]
  Foo3b :: Foo3 [Bool]
data instance Foo3 [a] where
  Foo3c :: Foo3 [a]
  Foo3d :: Foo3 [Char]
