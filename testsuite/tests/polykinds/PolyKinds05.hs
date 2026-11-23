
module PolyKinds05 where

data A f
data B = B1 (A Maybe)

-- Should work. `A` gets the polymorphic kind
--   forall k. k -> *
