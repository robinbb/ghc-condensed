{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UnliftedNewtypes #-}

module T15883e where

import GHC.Exts
import Data.Data (Data)

newtype Foo rep = MkFoo (forall (a :: TYPE rep). a)
deriving stock instance Data (Foo (BoxedRep Lifted))


