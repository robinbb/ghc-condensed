{-# LANGUAGE TypeFamilies,
             AllowAmbiguousTypes #-}
module T7278 where

import Data.Kind (Type)
 
type family TF (t  :: k) :: Type -> Type -> Type

class C (t :: k) (dcs :: Type -> Type -> Type)

f :: (C (t :: k) (TF t)) => TF t p1 p0 -> t p1 p0
f = undefined -- panic caused by (t :: k) in the signature's context
