
{-# OPTIONS_GHC -XFunctionalDependencies #-}

module Foo where

class Foo a b | a -> b

