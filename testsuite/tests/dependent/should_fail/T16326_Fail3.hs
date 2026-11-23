{-# LANGUAGE PatternSynonyms #-}
module T16326_Fail3 where

pattern Nil :: forall a -> [a]
pattern Nil <- undefined
