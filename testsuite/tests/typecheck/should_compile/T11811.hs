{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE GADTs #-}

module T11811 where

import Data.Kind

data Test (a :: x) (b :: x) :: x -> Type
  where K :: Test Int Bool Double
