{-# LANGUAGE UnliftedNewtypes, StandaloneKindSignatures, TypeFamilies, GADTs #-}

module T18357a where

import Data.Kind
import GHC.Exts

newtype T :: TYPE r where
  MkT :: Int -> T

