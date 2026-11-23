{-# LANGUAGE TypeFamilies #-}
module FancyContextsWithoutExtension2 where

import Data.Kind (Type)

type family Indexed a :: Type -> Constraint
type instance Indexed Int = Show
type instance Indexed Bool = Num

f :: (Indexed Int a) => a -> a
f = undefined