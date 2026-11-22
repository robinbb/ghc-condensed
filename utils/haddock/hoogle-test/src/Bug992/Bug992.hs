{-# LANGUAGE Haskell2010 #-}

module Bug992 where

import Data.Kind (Type)

data K (m :: Type -> Type) = K
