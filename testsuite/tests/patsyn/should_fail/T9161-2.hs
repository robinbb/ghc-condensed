{-# LANGUAGE PatternSynonyms #-}

module Bug where

import Data.Kind (Type)

pattern PATTERN = ()

data Proxy (tag :: k) (a :: Type)

wrongLift :: Proxy PATTERN ()
wrongLift = undefined
