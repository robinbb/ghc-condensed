{-# LANGUAGE MagicHash #-}
{-# LANGUAGE UnboxedTuples #-}

module T22291 where

import GHC.Exts

foo :: forall (lev :: Levity) (a :: TYPE (BoxedRep lev)). Addr# -> (# a #)
foo x = addrToAny# x
