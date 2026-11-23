{-# LANGUAGE TypeFamilies #-}

import Data.Kind (Type)

data family T1 a :: Type -> Type
data instance T1 Int           = T1_1   -- must fail: too few args
