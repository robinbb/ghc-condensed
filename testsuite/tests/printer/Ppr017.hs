{-# LANGUAGE PatternSynonyms #-}
module Imports( f, type (+), pattern Single ) where

import GHC.TypeLits

pattern Single x = [x]

f = undefined
