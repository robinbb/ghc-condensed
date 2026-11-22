{-# LANGUAGE TemplateHaskell, RequiredTypeArguments #-}
module T24572d where

idVis :: forall a -> a -> a
idVis _ a = a

[d| f :: forall a -> a ~ (:) => ()
    f (:) = ()|]

type (:#) = Bool

[d| h' :: forall a -> a ~ Bool => ()
    h' (:#) = ()|]
