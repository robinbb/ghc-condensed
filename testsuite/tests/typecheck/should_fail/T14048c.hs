{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE TypeFamilies #-}
module T14048c where

import Data.Kind

data family   Foo :: k
data instance Foo :: Constraint
