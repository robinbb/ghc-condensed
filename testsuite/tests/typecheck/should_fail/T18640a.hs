{-# LANGUAGE TypeAbstractions #-}
{-# LANGUAGE TypeFamilies #-}

module T18640a where

import Data.Kind

type F2 :: forall a b. Type -> a
type family F2 @a :: forall b. Type -> Type where
