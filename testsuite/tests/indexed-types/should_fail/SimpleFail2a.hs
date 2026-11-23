{-# LANGUAGE TypeFamilies #-}

module Simple2a where

import Data.Kind (Type)

class C a where
  data Sd a :: Type
  data Sn a :: Type
  type St a :: Type

instance C Int where
  data    Sd a = MkSd -- :: Type   -- Looks like a nullary data instance decl
  data    Sd Int = SdC Char
  newtype Sn Int = SnC Char
  type    St Int = Char
