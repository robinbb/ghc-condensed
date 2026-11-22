
{-# LANGUAGE GADTSyntax, KindSignatures #-}

module T20873c where

import Data.Kind ( Type )

type U a = Type

-- The return kind mentions Type, and U, which is simply a type synonym that
-- expands to Type.
data Foo :: U Type where
  MkFoo :: Foo
