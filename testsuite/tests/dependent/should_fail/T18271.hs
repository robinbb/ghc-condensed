{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE StandaloneDeriving #-}
module T18271 where

class C a
deriving instance forall a -> C (Maybe a)
