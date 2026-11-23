{-# LANGUAGE TypeFamilies #-}

module ShouldFail where

import Data.Kind (Type)

data family C9 a b :: Type
data instance C9 Int Int = C9IntInt
-- must fail: conflicting
data instance C9 Int Int = C9IntInt2

type family D9 a b :: Type
type instance D9 Int Int = Char
-- must fail: conflicting
type instance D9 Int Int = Int
