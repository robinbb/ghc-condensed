{-# OPTIONS_GHC -XArrows #-}
-- Test #2111

module Foo where

foo = do { rec { x <- undefined -< x }; undefined -< x }
