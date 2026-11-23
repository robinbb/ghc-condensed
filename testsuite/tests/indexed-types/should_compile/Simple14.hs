{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies, FlexibleContexts, ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators, AllowAmbiguousTypes #-}

module Simple14 where


import Data.Kind (Type)
data EQ_ (x :: Type) (y :: Type) = EQ_

-- Nov 2014: actually eqE has an ambiguous type
-- Apr 2020: now it doesn't again
eqE :: EQ_ x y -> (x~y => EQ_ z z) -> p
eqE x y = error "eqE"

eqI :: EQ_ x x
eqI = error "eqI"

ntI :: (forall p. EQ_ x y -> p) -> EQ_ x y
ntI x = error "ntI"

foo :: forall m n. EQ_ (Maybe m) (Maybe n)
foo = ntI (\eq -> eq `eqE` (eqI :: EQ_ m n))
-- Aug 2024: this test started passing with the fix to #25029
-- See Note [Defaulting equalities] in GHC.Tc.Solver

-- eq :: EQ_ (Maybe m) (Maybe n)
-- Need (Maybe m ~ Maybe n) =>  EQ_ m n ~ EQ_ zeta zeta
-- which reduces to (m~n) => m ~ zeta, but then
-- we were stuck; now we default zeta:=m in tryDefaulting
