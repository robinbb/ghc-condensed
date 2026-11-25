{-# LANGUAGE PatternSynonyms #-}
module ShouldCompile (data Single) where

pattern Single x <- [x]
