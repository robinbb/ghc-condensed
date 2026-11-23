{-# LANGUAGE TypeFamilies #-}

module ShouldFail where

import Data.Kind (Type)

type family C a :: Type

data family D a :: Type
-- must fail: lhs contains a type family application
data instance D [C a] = DC

type family E a :: Type
-- must fail: lhs contains a type family application
type instance E [C a] = Int
