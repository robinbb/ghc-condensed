{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE UnicodeSyntax #-}
module Linear8 where

correctLCase :: Int ⊸ Bool -> Int
correctLCase n = \case
  True -> n
  False -> n
