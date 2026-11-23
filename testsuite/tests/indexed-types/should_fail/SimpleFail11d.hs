{-# LANGUAGE TypeFamilies #-}

module ShouldFail where

import Data.Kind (Type)

data family C9 a b :: Type
data instance C9 Int Int = C9IntInt
data instance C9 [a] Int = C9ListInt
data instance C9 [Int] [a]   = C9ListList2
-- must fail: conflicting
data instance C9 [a]   [Int] = C9ListList
