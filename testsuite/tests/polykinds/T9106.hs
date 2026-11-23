{-# LANGUAGE FunctionalDependencies,
   FlexibleInstances, FlexibleContexts,
   UndecidableInstances #-}

module T9106 where

import Data.Kind (Type)
import GHC.TypeLits

class FunctorN (n :: Nat) f (a :: Type) (fa :: Type) | n f a -> fa where

instance FunctorN 0 f a a where

instance FunctorN n f a (f fa)

