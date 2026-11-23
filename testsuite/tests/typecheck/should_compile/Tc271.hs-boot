{-# LANGUAGE Haskell2010 #-}
module Tc271 where

import Data.Kind (Type)

class K (a :: Type) where

h :: K a => a -> a
