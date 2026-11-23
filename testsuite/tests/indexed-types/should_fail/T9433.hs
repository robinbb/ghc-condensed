{-# LANGUAGE
     TypeFamilies
   #-}

module T9433 where

import Data.Kind (Type)

type family Id x :: Type
type instance Id a = a

type family Map (f :: Type -> Type) x :: Type
type instance Map f [a] = [f a]

x :: Map Id [Bool]
x = []
