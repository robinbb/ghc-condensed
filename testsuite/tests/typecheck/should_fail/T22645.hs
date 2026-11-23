module T22645 where

import Data.Kind (Type)
import Data.Coerce

type T :: (Type -> Type) -> Type -> Type
data T m a = MkT (m a)

p :: Coercible a b => T Maybe a -> T Maybe b
p = coerce
