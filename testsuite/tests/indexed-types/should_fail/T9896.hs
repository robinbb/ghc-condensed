{-# LANGUAGE TypeFamilies #-}
module T9896 where

import Data.Kind (Type)

class Test a where
  type TestT a :: Type

instance Test Bool where
  newtype TestT Bool = Int
