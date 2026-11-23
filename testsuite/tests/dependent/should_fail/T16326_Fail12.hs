{-# LANGUAGE QuantifiedConstraints #-}
module T16326_Fail12 where

class (forall a -> Show a) => C a
