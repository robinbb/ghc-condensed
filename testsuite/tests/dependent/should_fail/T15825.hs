{-# Language FlexibleInstances #-}

{-# Options_GHC -dcore-lint #-}

module T15825 where

import Data.Kind (Type)

type C k = (forall (x::k). Type)

class                         X (a :: Type)
instance forall k (a :: C k). X (a :: Type)
