{-# LANGUAGE PolyKinds, PatternSynonyms, GADTs  #-}

module T8966 where

import Data.Kind (Type)

data NQ :: [k] -> Type where
   D :: NQ '[a]

pattern Q = D
