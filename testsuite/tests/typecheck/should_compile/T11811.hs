{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE GADTs, StandaloneKindSignatures #-}

module T11811 where

import Data.Kind

type Test :: forall x. x -> x -> x -> Type
data Test (a :: x) (b :: x) :: x -> Type
  where K :: Test Int Bool Double
