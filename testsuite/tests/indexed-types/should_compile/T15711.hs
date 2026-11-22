{-# LANGUAGE TypeFamilies, PolyKinds #-}

module Bug where

class C a where
  type F (x :: Maybe a)
