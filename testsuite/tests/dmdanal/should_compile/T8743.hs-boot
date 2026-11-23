{-# LANGUAGE Haskell2010 #-}
module T8743 where

import Data.Kind (Type)
class ToRow (a :: Type)
instance ToRow (Maybe a)
