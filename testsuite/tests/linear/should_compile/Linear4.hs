{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE UnicodeSyntax #-}
{-# LANGUAGE GADTs #-}
module Linear4 where

correctCase :: Bool ⊸ a ⊸ a
correctCase x n =
  case x of
    True -> n
    False -> n
