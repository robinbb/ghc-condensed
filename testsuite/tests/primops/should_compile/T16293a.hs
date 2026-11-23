{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE TypeApplications #-}
module T16293a where


import Data.Kind (Type)
import Data.Coerce
import Data.Proxy
import GHC.Exts

test1a :: () -> Proxy Int
test1a _ = Proxy @Int

test1b :: () -> Proxy# Int
test1b _ = proxy# @Int

test2a :: (() -> Proxy (a :: Type)) -> (() -> Proxy (b :: Type))
test2a = coerce

test2b :: (() -> Proxy# (a :: Type)) -> (() -> Proxy# (b :: Type))
test2b = coerce
