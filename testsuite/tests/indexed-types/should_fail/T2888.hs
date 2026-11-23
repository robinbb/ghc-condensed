{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}
-- Test for no type indices

module T2888 where

import Data.Kind (Type)

class C w where 
  data D:: Type -> Type
