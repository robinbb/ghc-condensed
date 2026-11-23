{-# LANGUAGE Haskell2010 #-}
module Bug where

foo :: foral a. a -> a
foo x = x
