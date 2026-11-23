{-# LANGUAGE TypeFamilies #-}

module ShouldFail where

import Data.Kind (Type)

-- must fail: AT must be in class instance
class C5 a where
  data S5 a :: Type
data instance S5 Int = S5
