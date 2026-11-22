{-# LANGUAGE UnboxedTuples, UnliftedNewtypes, MagicHash #-}
module T24306 where

import GHC.Exts

newtype A = MkA (# #)
data T = T Int# A Int#

x = T 1# (MkA (# #)) 2#
