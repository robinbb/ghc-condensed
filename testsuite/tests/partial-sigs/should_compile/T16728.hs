{-# LANGUAGE PartialTypeSignatures #-}
module Bug where

import Data.Proxy

f :: forall k (x :: k). Proxy (x :: _)
f = Proxy
