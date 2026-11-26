{-# LANGUAGE UnicodeSyntax #-}
module T8959b where

foo :: Int -> Int
foo = ()

baz = () :: (forall a. a -> a) -> a

