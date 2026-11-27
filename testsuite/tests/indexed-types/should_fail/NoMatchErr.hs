{-# LANGUAGE TypeFamilies #-}

-- Type error message looks like
--      TF.hs:12:11:
--    Couldn't match expected type `Memo d'
--           against inferred type `Memo d1'
--      NB: `Memo' is a (non-injective) type function
--
-- Note the "NB", which helps point out the problem

module Foo where

import Data.Kind (Type)

class Fun d where
    type Memo d :: Type -> Type
    abst :: (d -> a) -> Memo d a
    appl :: Memo d a -> (d -> a)

f ::  (Fun d) => Memo d a -> Memo d a    -- (1)
f = abst . appl

