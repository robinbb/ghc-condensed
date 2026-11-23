{-# LANGUAGE StandaloneKindSignatures #-}
{-# LANGUAGE RankNTypes, TypeFamilies #-}

module SAKS_Fail021 where

import Data.Kind
import Data.Proxy

type C :: Type -> Constraint
class C (a :: k) where
  type F k
