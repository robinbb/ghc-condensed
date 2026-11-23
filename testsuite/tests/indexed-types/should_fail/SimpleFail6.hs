{-# LANGUAGE TypeFamilies #-}

module ShouldFail where

import Data.Kind (Type)

-- must fail: Repeated type variable
class C4 a where
  data S4 a a :: Type
