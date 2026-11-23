{-# LANGUAGE PatternSynonyms #-}

module Bug where

pattern PATTERN = ()

data Proxy (tag :: k) (a :: *)

wrongLift :: Proxy PATTERN ()
wrongLift = undefined
