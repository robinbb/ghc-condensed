{-# LANGUAGE PolyKinds, FunctionalDependencies, KindSignatures, DataKinds #-}

module T6054a where

class Bar a (p :: Bool) | a -> p
data Proxy a = Proxy deriving Show
