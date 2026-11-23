
module BadTelescope2 where

import Data.Kind

data SameKind :: k -> k -> Type

foo :: forall a k (b :: k). SameKind a b
foo = undefined

