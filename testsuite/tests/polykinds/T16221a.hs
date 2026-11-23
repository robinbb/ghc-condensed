{-# LANGUAGE ExistentialQuantification #-}

module T16221a where

import Data.Kind (Type)

data SameKind :: k -> k -> Type
data T2 a = forall k (b :: k). MkT2 (SameKind a b) !Int

