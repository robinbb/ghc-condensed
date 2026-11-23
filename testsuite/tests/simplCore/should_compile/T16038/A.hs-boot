{-# LANGUAGE Haskell2010 #-}
module A where


import Data.Kind (Type)
data HsExpr (i :: Type)

instance Eq i => Eq (HsExpr i)

