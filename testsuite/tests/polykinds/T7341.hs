{-# LANGUAGE TypeFamilies, FlexibleInstances #-}

module T7341 where

import Data.Kind (Type)

data Proxy a = Proxy

class C a where
  type F (a :: Type) :: Type
  op :: Proxy a -> Int

instance C [] where
  op _ = 5
