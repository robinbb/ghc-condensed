{-# OPTIONS_GHC -fdefer-type-errors #-}
{-# LANGUAGE TypeApplications
#-}

module T19142 where

import Data.Kind (Type)

-- Both these examples gave Lint errors
-- NB: the -fdefer-type-errors at the top!!

-- Example 1
f (x :: Maybe Maybe) = x

-- Example 2
foo :: forall (f :: Type -> Type) . String
foo = ""

g x = foo @Int
