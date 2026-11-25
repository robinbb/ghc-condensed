{-# LANGUAGE RequiredTypeArguments #-}

module T22326_fail_match where

f :: forall t -> t -> ()
f (type (Maybe a)) x = ()