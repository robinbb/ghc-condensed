{-# LANGUAGE TypeFamilies #-}


module ShouldFail where

import Data.Kind (Type)

type family C a :: Type
-- must fail: rhs is not a tau type
type instance C Int = forall a. [a]

