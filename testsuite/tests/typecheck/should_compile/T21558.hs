{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
module T21558 where

import Data.Kind (Type)
import Data.Map

type family IxValue (m :: Type) :: Type
type family Index (m :: Type) :: Type

data Op a where
  Insert :: (a ~ Map (Index a) (IxValue a)) => (Int, Index a, IxValue a) -> Op a

instance Eq (Op a) where

instance (Ord (Index a), Ord (IxValue a), Ord a) => Ord (Op a) where
  compare (Insert a1) (Insert b1) = compare a1 b1
