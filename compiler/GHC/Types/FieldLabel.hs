{-# LANGUAGE UndecidableInstances #-}

{-
%
% (c) Adam Gundry 2013-2015
%

Note [FieldLabel]
~~~~~~~~~~~~~~~~~
This module defines the representation of FieldLabels as stored in
TyCons.  As well as a selector name, these record whether the
NoFieldSelectors extension was on in the defining module.

In the normal case (with FieldSelectors), a datatype like

    data T = MkT { foo :: Int }

has

    FieldLabel { flHasFieldSelector = FieldSelectors
               , flSelector         = foo }.

We need to keep track of whether FieldSelectors was enabled when a record
field was defined, as it affects name resolution and shadowing of record
fields, as explained in Note [NoFieldSelectors] in GHC.Types.Name.Reader
and Note [Reporting duplicate local declarations] in GHC.Rename.Names.
-}

module GHC.Types.FieldLabel
   ( FieldLabelEnv
   , FieldLabel(..), flLabel
   , FieldSelectors(..)
   )
where

import GHC.Prelude

import {-# SOURCE #-} GHC.Types.Name

import GHC.Utils.Outputable
import GHC.Utils.Binary
import GHC.Data.FastString

import Language.Haskell.Syntax.Basic (FieldLabelString(..))
import Language.Haskell.Syntax.Text

import Control.DeepSeq
import Data.Bool
import Data.Data
import qualified Data.Map as M

-- | A map from labels to all the auxiliary information
type FieldLabelEnv = M.Map HText FieldLabel

-- | Fields in an algebraic record type; see Note [FieldLabel].
data FieldLabel = FieldLabel {
      flHasFieldSelector :: FieldSelectors,
      -- ^ Was @FieldSelectors@ enabled in the defining module for this datatype?
      -- See Note [NoFieldSelectors] in GHC.Rename.Env
      flSelector :: Name
      -- ^ The 'Name' of the selector function, which uniquely identifies
      -- the field label.
    }
  deriving (Data, Eq)

-- | User-visible label of a field.
flLabel :: FieldLabel -> FieldLabelString
flLabel = FieldLabelString . fastStringToShortText . occNameFS . nameOccName . flSelector

instance HasOccName FieldLabel where
  occName = nameOccName . flSelector

instance Outputable FieldLabel where
    ppr fl = ppr (flLabel fl) <> whenPprDebug (braces (ppr (flSelector fl))
                                                <> ppr (flHasFieldSelector fl))

-- | Flag to indicate whether the FieldSelectors extension is enabled.
data FieldSelectors
    = FieldSelectors   -- ^ Selector functions are available (the default)
    | NoFieldSelectors -- ^ Selector functions are not available
  deriving (Show, Eq, Data)

instance Binary FieldSelectors where
    put_ bh f = put_ bh (f == FieldSelectors)
    get bh = bool NoFieldSelectors FieldSelectors <$> get bh

instance Outputable FieldSelectors where
    ppr FieldSelectors   = text "+sel"
    ppr NoFieldSelectors = text "-sel"

instance NFData FieldSelectors where
  rnf FieldSelectors   = ()
  rnf NoFieldSelectors = ()

-- | We need the @Binary Name@ constraint here even though there is an instance
-- defined in "GHC.Types.Name", because the we have a SOURCE import, so the
-- instance is not in scope.  And the instance cannot be added to Name.hs-boot
-- because "GHC.Utils.Binary" itself depends on "GHC.Types.Name".
instance Binary Name => Binary FieldLabel where
    put_ bh (FieldLabel aa ab) = do
        put_ bh aa
        put_ bh ab
    get bh = do
        aa <- get bh
        ab <- get bh
        return (FieldLabel aa ab)
