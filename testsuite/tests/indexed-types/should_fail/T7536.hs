{-# LANGUAGE TypeFamilies #-}

module T7536 where

import Data.Kind (Type)

type T v = Int

type family TF a :: Type
type instance TF (T a) = a

