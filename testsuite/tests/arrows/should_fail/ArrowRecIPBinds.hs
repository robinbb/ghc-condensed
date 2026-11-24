{-# LANGUAGE Arrows, ImplicitParams #-}
module ArrowRecIPBinds where

import Control.Arrow

f :: Arrow a => a Int Int
f = proc x -> do
  rec { let { ?y = x }
      ; z <- returnA -< ?y }
  returnA -< z
