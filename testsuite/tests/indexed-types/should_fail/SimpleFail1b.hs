{-# LANGUAGE TypeFamilies #-}

import Data.Kind (Type)

data family T1 a :: Type -> Type
data instance T1 Int Bool Char = T1_3   -- must fail: too many args
