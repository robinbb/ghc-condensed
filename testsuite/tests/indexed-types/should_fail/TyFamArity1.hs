{-# LANGUAGE TypeFamilies #-}

import Data.Kind (Type)

type family T a b :: Type
type instance T Int = IO   -- must fail: too few args
