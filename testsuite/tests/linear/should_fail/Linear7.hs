{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE UnicodeSyntax #-}
module Linear7 where

incorrectLCase :: Int ⊸ Bool -> Int
incorrectLCase n = \case
  True -> n
  False -> 0
