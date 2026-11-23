{-# LANGUAGE GADTs #-}
{-# LANGUAGE UnliftedNewtypes #-}

module UnliftedNewtypesLevityBinder where

import GHC.Types (RuntimeRep,TYPE,Coercible)

newtype Ident :: forall (r :: RuntimeRep). TYPE r -> TYPE r where
  IdentC :: forall (r :: RuntimeRep) (a :: TYPE r). a -> Ident a

bad :: forall (r :: RuntimeRep) (a :: TYPE r). a -> Ident a
bad = IdentC
