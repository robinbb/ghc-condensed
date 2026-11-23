
module T11203 where

import Data.Kind (Type)

data SameKind :: k -> k -> Type

data Q (a :: k1) (b :: k2) c = MkQ (SameKind a b)
