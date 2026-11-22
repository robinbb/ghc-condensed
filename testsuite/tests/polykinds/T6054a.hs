{-# LANGUAGE PolyKinds, FunctionalDependencies, KindSignatures #-}

module T6054a where

class Bar a (p :: Bool) | a -> p
data Proxy a = Proxy deriving Show
