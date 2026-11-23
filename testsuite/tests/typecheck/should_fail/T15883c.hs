{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UnliftedNewtypes #-}

module T15883c where

import GHC.Exts

newtype Foo rep = MkFoo (forall (a :: TYPE rep). a)
deriving stock instance Ord (Foo (BoxedRep Lifted))
