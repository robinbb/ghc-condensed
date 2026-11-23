{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE QuasiQuotes #-}
module T15360b where

import Data.Kind
import Data.Proxy

x :: Proxy $([t| Type Double |])
x = Proxy

y :: Proxy $([t| 1 Int |])
y = Proxy

z :: Proxy $([t| Constraint Bool |])
z = Proxy

w :: Proxy $([t| '[] Int |])
w = Proxy
