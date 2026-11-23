{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE ForeignFunctionInterface #-}
module Foo where

import Foreign
type X u = Ptr ()
foreign import ccall bla :: (forall u. X u) -> IO ()

