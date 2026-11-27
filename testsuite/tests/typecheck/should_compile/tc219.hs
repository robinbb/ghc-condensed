{-# LANGUAGE ImplicitParams #-}

module ShouldCompile where

-- c.f. tc218.hs, only no type signature here
-- Instead, bar is generalised over ?c
bar = show ?c

foo1 = let { ?c = 'x' } in bar
foo2 = let { ?c = True } in bar
