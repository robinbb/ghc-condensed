module GHC.Core where
import Data.Kind ( Type )
import {-# SOURCE #-} GHC.Types.Var

data Expr (a :: Type)

type CoreBndr = Var

type CoreExpr = Expr CoreBndr
