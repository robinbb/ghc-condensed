
module Foo where

f :: Read a => a
-- f gets a polymorphic type because the pattern binding
-- is generalised
(f, _) = (read "3", True)

g :: Read a => a
g = f
