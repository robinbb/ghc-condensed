{-# LANGUAGE FlexibleContexts #-}

module T1 where



g :: Int -> Char

g _ = 'a'



f :: Int -> Show Int => ()
f = g
