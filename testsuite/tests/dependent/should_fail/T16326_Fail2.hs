{-# LANGUAGE ForeignFunctionInterface #-}
module T16326_Fail2 where

foreign import ccall "blah" blah :: forall a -> a -> IO ()
