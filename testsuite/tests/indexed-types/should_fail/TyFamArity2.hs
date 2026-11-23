{-# LANGUAGE TypeFamilies #-}

import Data.Kind (Type)

type family T a :: Type -> Type
type instance T Int Float = Char   -- must fail: extra arguments
