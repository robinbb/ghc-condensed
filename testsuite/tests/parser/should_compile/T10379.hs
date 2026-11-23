{-# LANGUAGE GADTs #-}
module Foo where

import Data.Kind (Type)

data Foo1 :: [Type] -> Type where

-- ghc <= 7.10 reported (before "Add kind equalities to GHC"):
--
--     T10379.hs:9:16: parse error on input ‘]’
data Foo2 :: ([] Type) -> Type where
