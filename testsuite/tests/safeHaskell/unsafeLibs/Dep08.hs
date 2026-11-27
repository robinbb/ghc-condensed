{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE Safe #-}
module Dep08 where

import GHC.IOArray

bad1 = unsafeReadIOArray

bad2 = unsafeWriteIOArray

