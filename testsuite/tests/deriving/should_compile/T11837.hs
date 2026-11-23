{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module T11837 where

import Data.Kind (Type)

class Category (cat :: k -> k -> Type) where
  catId   :: cat a a
  catComp :: cat b c -> cat a b -> cat a c

newtype T (c :: k -> k -> Type) a b = MkT (c a b) deriving Category
