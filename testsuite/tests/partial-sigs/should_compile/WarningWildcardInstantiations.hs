{-# LANGUAGE PartialTypeSignatures, NamedWildCards, ScopedTypeVariables #-}
module WildcardInstantiations where


foo :: (Show _a, _) => _a -> _
foo x = show (succ x)

bar :: _ -> _ -> _
bar x y = y x
