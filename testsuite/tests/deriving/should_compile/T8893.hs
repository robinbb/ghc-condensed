{-# OPTIONS_GHC -Wall #-}
{-# Language DeriveFunctor #-}

module T8893 where

data V a = V [a] deriving Functor

data C x a = C (V (P x a)) deriving Functor

data P x a = P (x a) deriving Functor
