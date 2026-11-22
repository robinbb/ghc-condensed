{-# language MagicHash #-}
{-# language GADTSyntax #-}
{-# language UnliftedNewtypes #-}

module UnliftedNewtypesMismatchedKind where

import Data.Kind (Type)
import GHC.Exts

newtype T :: Type where
  MkT :: Int# -> T
