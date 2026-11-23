{-# Language LiberalTypeSynonyms #-}
{-# Language RankNTypes          #-}

import Data.Kind

type Cat ob = ob -> ob -> Type

data Zero :: forall (cat :: forall xx. xx -> Type) a. forall b. Cat (forall b. cat b u)
