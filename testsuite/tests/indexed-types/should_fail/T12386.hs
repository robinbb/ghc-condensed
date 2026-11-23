{-# LANGUAGE TypeFamilies #-}

module T12386 where

import Data.Kind (Type)

class C a where
   type family F a t :: Type

   type family T a :: Type
   type T a = F a
