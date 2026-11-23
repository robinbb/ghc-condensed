{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UnliftedNewtypes #-}

module T15883d where

import GHC.Exts

newtype Foo rep = MkFoo (forall (a :: TYPE rep). a)
deriving stock instance Show (Foo (BoxedRep Lifted))

