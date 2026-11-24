
{-# LANGUAGE MonadComprehensions #-}

module Foo where

import Control.Monad.Zip

foo :: MonadZip m => m ()
foo = [ ()
      | () <- foo
      | () <- foo
      ]

