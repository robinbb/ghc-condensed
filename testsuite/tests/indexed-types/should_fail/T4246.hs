{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies, FlexibleInstances #-}
module T4246 where

import Data.Kind (Type)

class Stupid a where
   type F a

instance {-# OVERLAPPABLE #-} Stupid a where
   type F a = a

instance {-# OVERLAPPING #-} Stupid Int where
   type F Int = Bool

type family G a :: Type
type instance G Int = Int
type instance G Int = Bool
