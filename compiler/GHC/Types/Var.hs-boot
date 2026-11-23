module GHC.Types.Var where

import Data.Kind ( Type )
import {-# SOURCE #-} GHC.Types.Name
import Language.Haskell.Syntax.Specificity (Specificity)

data FunTyFlag
data ForAllTyFlag
data Var
instance NamedThing Var
data VarBndr (var :: Type) (argf :: Type)
type TyVar = Var
type Id    = Var
type TyCoVar = Id
type TcTyVar = Var
type InvisTVBinder = VarBndr TyVar Specificity
type TyVarBinder   = VarBndr TyVar ForAllTyFlag
