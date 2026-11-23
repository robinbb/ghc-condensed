{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}
module Bug466 where

import Data.Kind (Type)

class Cl a where
  type Fam a :: [Type]

data X = X
instance Cl X where
  type Fam X = '[Char]
