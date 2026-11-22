{-# LANGUAGE Haskell2010 #-}
{-# OPTIONS_GHC -w #-}
-- | Safe, as we now check at overlap occurrence, not definition.
module UnsafeInfered08_A where

g :: Int
g = 1

