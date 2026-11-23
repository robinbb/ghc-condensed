{-# LANGUAGE PartialTypeSignatures, TypeFamilies #-}
module WildcardInTypeFamilyInstanceRHS where

import Data.Kind (Type)

class Foo k where
  type Dual k :: Type

instance Foo Int where
  type Dual Int = Maybe _
