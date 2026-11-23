
module T7696 where

import Data.Kind (Type)

f1 :: (m a, t m)
f1 = undefined

f2 :: ((), w ())
f2 = f1

{-
m :: Type -> Type
t :: (Type -> Type) -> Type
a :: Type
w :: Type -> Type

m a ~ ()
t m ~ w ()
-}
