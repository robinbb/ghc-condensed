{-# OPTIONS_GHC -fno-warn-redundant-constraints #-}
{-# LANGUAGE FlexibleContexts, FunctionalDependencies #-}

module T6134 where

class C a b | a -> b 

f :: C Int b => Int -> Int
f = undefined
