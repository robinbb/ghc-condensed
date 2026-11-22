{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -fwarn-safe #-}
module SafeInfered05_A where

class C a where
  f :: a -> String

instance {-# OVERLAPPING #-} C [Int] where
  f _ = "[Int]"

