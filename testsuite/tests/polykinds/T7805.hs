{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}
module T7805 where

data HigherRank = HR (forall a. a -> a)

type family F (x :: HigherRank)
type instance F (HR x) = Bool
