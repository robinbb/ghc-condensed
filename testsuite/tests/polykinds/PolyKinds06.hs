{-# LANGUAGE GADTs                      #-}

module PolyKinds06 where

import Data.Kind (Type)


data A = A1 | A2 (B 'B1)

data B :: A -> Type where
  B1 :: B 'A1
