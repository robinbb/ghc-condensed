{-# LANGUAGE LinearTypes #-}
module LinearKind where

import Data.Kind (Type)

data A :: Type %1 -> Type
