{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE RankNTypes #-}

module T3101 where

import Data.Kind (Type)

type family F a :: Type

data Boom = Boom (forall a. a -> F a)
  deriving Show
