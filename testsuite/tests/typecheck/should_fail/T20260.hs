{-# LANGUAGE TypeFamilies #-}
module T20260 where

import Data.Kind (Type)

data Bar

type Foo :: Type
type family Foo where
  Bar = ()
