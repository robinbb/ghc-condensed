{-# LANGUAGE TypeFamilies, GADTs #-}

module T12444a where

import Data.Kind (Type)

type family F a :: Type
type instance F (Maybe x) = Maybe (F x)

foo :: a -> Maybe (F a)
foo = undefined

-- bad :: (F (Maybe t) ~ t) => Maybe t -> [Maybe t]
bad x = [x, foo x]
