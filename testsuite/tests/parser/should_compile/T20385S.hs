{-# LANGUAGE MultiWayIf #-}
module Main where

main = pure ()

foo :: forall a. a -> a
foo x = if | otherwise -> (x :: a)
