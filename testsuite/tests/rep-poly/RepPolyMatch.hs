{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module RepPolyMatch where

import GHC.Exts

match :: forall rep (a :: TYPE rep). a -> ()
match = \ case {}
