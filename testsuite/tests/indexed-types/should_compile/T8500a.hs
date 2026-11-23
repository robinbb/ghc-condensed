{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}

module T8500a where

import Data.Kind (Type)

class C (a :: Type) where
   type F a
   type F a = [a]
