{-# LANGUAGE TypeFamilies #-}

module ShouldFail where

import Data.Kind (Type)

class C1 a where
  data S1 a :: Type

-- must fail: wrong category of type instance
instance C1 Int where
  type S1 Int = Bool
