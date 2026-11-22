{-# LANGUAGE NoPolyKinds #-}

module T11334b where

import Data.Functor.Compose
import Data.Proxy

p = Proxy :: Proxy 'Compose
