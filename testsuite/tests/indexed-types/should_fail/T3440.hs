{-# LANGUAGE TypeFamilies, GADTs #-}

module T3440 where

import Data.Kind (Type)

type family Fam a :: Type

data GADT :: Type -> Type where
   GADT :: a -> Fam a -> GADT (Fam a)

unwrap :: GADT (Fam a) -> (a, Fam a)
unwrap (GADT x y) = (x, y)
