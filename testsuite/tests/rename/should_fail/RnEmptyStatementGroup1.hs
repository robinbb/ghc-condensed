{-# LANGUAGE TransformListComp #-}

module ShouldFail where

one = [() | then ()]

two = do
