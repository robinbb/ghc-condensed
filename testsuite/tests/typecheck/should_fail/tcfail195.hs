{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE GADTs #-}

module ShouldFail where

data Foo a where
  Foo :: Int -> Foo (forall a. a)
