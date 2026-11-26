module Main where

import Prelude

{-# LANGUAGE MultiWayIf #-}

main = pure ()

foo :: forall a. a -> a
foo x = multiWayIf x
