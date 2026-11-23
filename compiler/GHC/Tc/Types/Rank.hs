module GHC.Tc.Types.Rank (Rank(..))  where

import GHC.Utils.Outputable (Outputable, ppr, text)

data Rank = ArbitraryRank -- Any rank ok

          -- Monotypes that could be a polytype through an extension
          | MonoTypeTyConArg   -- ImpredicativeTypes
          | MonoTypeSynArg     -- LiberalTypeSynonyms
          | MonoTypeConstraint -- QuantifiedConstraints
          --

          | MustBeMonoType  -- Monotype regardless of flags

instance Outputable Rank where
  ppr ArbitraryRank      = text "ArbitraryRank"
  ppr MonoTypeTyConArg   = text "MonoTypeTyConArg"
  ppr MonoTypeSynArg     = text "MonoTypeSynArg"
  ppr MonoTypeConstraint = text "MonoTypeConstraint"
  ppr MustBeMonoType     = text "MustBeMonoType"
