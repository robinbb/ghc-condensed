module T24553 where

import Data.Kind (Type)
import GHC.Exts

type Foo :: Type -> forall r. TYPE r -> Type
newtype Foo m a = MkFoo ()

type Bar = Foo :: forall r. Type -> TYPE r -> Type
