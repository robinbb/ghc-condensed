{-# LANGUAGE Haskell2010 #-}
module T4003A where


import Data.Kind (Type)
import Data.Data

data HsExpr (i :: Type)

instance Data i => Data (HsExpr i)
