{-# Language    TypeFamilies        #-}
{-# Language    TypeApplications    #-}
{-# Language    TypeOperators       #-}
{-# Language    GADTs               #-}
{-# Language    FlexibleInstances   #-}

module T15797 where
import Data.Kind

class Ríki (obj :: Type) where
  type Obj :: obj -> Constraint
  type forall k . Obj = Bæ @k :: k -> Constraint

class    Bæ    (a :: k)
instance Bæ @k (a :: k)

data
  EQ :: forall ob. ob -> ob -> Type where
  EQ :: EQ a a

instance
  Ríki (EQ @ob)
