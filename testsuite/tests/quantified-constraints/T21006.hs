{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE UndecidableInstances #-}

module Err where

import Data.Kind (Type)
import GHC.Exts (Constraint)

class Determines b | -> b

class (forall (b :: Type) (c :: Constraint). (Determines b, Determines c) => c) => OpCode

instance OpCode
