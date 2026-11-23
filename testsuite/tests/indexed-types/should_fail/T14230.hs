{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
module T14230 where

import Data.Kind (Type)

class C k where
  data CD :: k -> k -> Type

instance C (Maybe a) where
  data forall k . CD :: (k -> Type) -> (k -> Type) -> Type
