{-# LANGUAGE TypeFamilies, LiberalTypeSynonyms #-}

module T2157 where

import Data.Kind (Type)

type S a b = a
type family F a :: Type -> Type
type instance F a = S a
