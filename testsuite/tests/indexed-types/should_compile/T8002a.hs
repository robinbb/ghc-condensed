{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE TypeFamilies #-}

module T8002a where

import Data.Kind (Type)

import T8002b

class QA (a :: Type) where
   type QRep a
   type QRep a = QRep (Maybe a)

instance QA () where
   type QRep () = ()
