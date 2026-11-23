{-# LANGUAGE TypeFamilies #-}
module T7892 where

import Data.Kind (Type)

class C (f :: Type -> Type) where
   type F (f :: Type) :: Type


