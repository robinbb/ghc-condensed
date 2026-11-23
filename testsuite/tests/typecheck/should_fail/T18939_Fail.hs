{-# LANGUAGE Haskell2010 #-}
module T18939_Fail where

data F (f :: forall a -> a)
