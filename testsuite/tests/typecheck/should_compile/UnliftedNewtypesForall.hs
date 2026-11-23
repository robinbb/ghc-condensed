{-# Language RankNTypes #-}
{-# Language UnliftedNewtypes #-}

module UnliftedNewtypesForall where

import GHC.Exts

newtype Foo rep = MkFoo (forall (a :: TYPE rep). a)
