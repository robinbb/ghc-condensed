{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
module Bug where

type family F a

g :: forall a. a
g = f
  where
    f :: (F b ~ a) => a
    f = undefined
