{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE RankNTypes #-}

module Foo where

import Data.Proxy

-- Should be illegal without PolyKinds
f :: forall k (a :: k). Proxy a
f = f
