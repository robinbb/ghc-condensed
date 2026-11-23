{-# LANGUAGE TypeFamilies #-}

import Data.Kind (Type)

class C a where
  data Sd a :: Type
  data Sn a :: Type
  type St a :: Type

instance C Int where
  data    Sd Int = SdC1 Char    -- must fail: conflicting
  data    Sd Int = SdC2 Char    --            declarations
  newtype Sn Int = SnC Char
  type    St Int = Char
