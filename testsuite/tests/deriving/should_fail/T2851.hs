{-# LANGUAGE TypeFamilies #-}
-- Test #2851

module T2851 where

import Data.Kind (Type)

type family F a :: Type

data D a = D (F a)
    deriving (Show)
