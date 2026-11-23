{-# LANGUAGE TypeFamilies #-}

module T8129 where

import Data.Kind (Type)

type family F (x :: Type) :: Type

class (y ~ F x) => C x y

z = () :: C x y => ()
