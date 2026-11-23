{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}

module ClosedFam2 where

import Data.Kind (Type)

type family Foo (b :: Type) :: Type where ..
