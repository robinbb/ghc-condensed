{-# Language TypeApplications         #-}

module Bug where

import Data.Kind

data Nat = Zero | Succ Nat

data D n = MkD @Nat Bool
