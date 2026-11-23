{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UnicodeSyntax #-}
module T12803a where

import Data.Kind (Type)

type Constrd a = Num a ⇒ a

data ADT a = ADT (Constrd a) ExistentiallyLost

data ExistentiallyLost = ∀ u. TC u ⇒ ExistentiallyLost u

class u ~ (ATF1 u, ATF2 u) ⇒ TC u where
    type ATF1    u ∷ Type
    type ATF2    u ∷ Type
    uie_handlers   ∷ ADT Int

-- Loop:
--  - ADT depends on ExistentiallyLost (also the Constrd appendage)
--  - ExistentiallyLost depends on TC
--  - TC depends on ADT
