{-# LANGUAGE ImplicitParams #-}

module T11793 where

class C a where
  op :: (?x::Int) => a -> a

-- An implicit-parameter constraint on a class method is fine (#11793)
