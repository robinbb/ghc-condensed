{-# LANGUAGE ImplicitParams #-}
module IPKind where

-- An implicit parameter is not a kind.
data T (a :: (?x :: Int)) = MkT
