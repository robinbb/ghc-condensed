{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}

module T9840a where


import Data.Kind (Type)
import {-# SOURCE #-} T9840

type family G (a :: Type) :: Type where

bar :: X a -> X a
bar = id
