{-# LANGUAGE PatternSynonyms #-}

module Bug where

pattern PATTERN = ()

wrongLift :: PATTERN
wrongLift = undefined
