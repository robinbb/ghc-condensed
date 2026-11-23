{-# OPTIONS_GHC -fno-warn-redundant-constraints #-}

-- !!! Mis-matched contexts in a mutually recursive group

-- A binding with a type signature breaks its recursive group for
-- typing (generalised typing of mutually recursive bindings), so
-- this test always succeeds

module ShouldFail where

f :: (Ord d) => d -> d
f c = g c

g :: e -> e
g c = c
  where p = f (1 :: Int)
