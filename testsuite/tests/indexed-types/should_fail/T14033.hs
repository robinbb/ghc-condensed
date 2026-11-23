{-# LANGUAGE TypeFamilies #-}

module T14033 where

import Data.Kind (Type)

newtype Zero = Zero
newtype Succ a = Succ a

type family Add n m :: Type where
     Add Zero m = m
     Add (Succ n) m = Succ (Add n m)
