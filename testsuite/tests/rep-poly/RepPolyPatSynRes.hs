{-# LANGUAGE Haskell2010 #-}

{-# LANGUAGE GADTs #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}

module RepPolyPatSynRes where

import GHC.Exts

pattern Pat :: forall rep (a :: TYPE rep). ( () ~ () ) => a
pattern Pat <- ( undefined -> True )
