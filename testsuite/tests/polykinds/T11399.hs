{-# LANGUAGE FlexibleInstances #-}
module T11399 where

import Data.Kind

newtype UhOh (k :: Type -> Type) (a :: k Type) = UhOh (k Type)

-- UhOh :: forall (k : Type -> Type). k Type -> Type

instance Functor a => Functor (UhOh a) where

{- Functor expects (Type -> Type)
   (UhOh a) :: k Type -> Type
-}