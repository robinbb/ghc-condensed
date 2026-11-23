{-# LANGUAGE TypeFamilies #-}

module ExplicitSpecificity3 where

import Data.Kind (Type)

type family F {k} (a::k) :: Type
type instance F String = Int

