{-# LANGUAGE PatternSynonyms, ViewPatterns, TypeFamilies #-}

module T12819 where

import Data.Kind (Type)

type family F a  -- F :: Type -> Type
data T :: (Type -> Type) -> Type

pattern Q :: T F -> String
pattern Q x <- (undefined -> x)
