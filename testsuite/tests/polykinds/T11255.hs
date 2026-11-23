{-# LANGUAGE TypeFamilies, UndecidableInstances #-}

module T11255 where

type family Default :: k
type instance Default = '(Default, Default)
