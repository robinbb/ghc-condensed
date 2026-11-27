{-# LANGUAGE FlexibleInstances, UndecidableInstances,
             TypeFamilies, FunctionalDependencies #-}

module T10778 where

import Data.Kind (Type)

type family F a :: Type
class C a b | a -> b

instance C p (F q) => C p [q]
-- This instance should fail the (liberal) coverage condition
