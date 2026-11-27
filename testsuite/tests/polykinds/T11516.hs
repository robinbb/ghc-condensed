{-# language ConstraintKinds #-}
{-# language FlexibleInstances #-}
{-# language FunctionalDependencies #-}
{-# language UndecidableInstances #-}

import Data.Kind (Type)
import GHC.Exts (Constraint)

class Ríki (p :: i -> i -> Type)
class (Ríki p) => Varpi p q f | f -> p q
instance Varpi () () f => Varpi (->) (->) (Either f) where
