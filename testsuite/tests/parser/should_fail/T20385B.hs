{-# LANGUAGE ScopedTypeVariables #-}
module Main where

import Prelude

{-# LANGUAGE LambdaCase #-}

main = pure ()

foo :: forall a. a -> a
foo x = lambdaCase x
