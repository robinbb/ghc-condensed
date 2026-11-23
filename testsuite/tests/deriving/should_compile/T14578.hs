{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module T14578 where


import Data.Kind (Type)
import Control.Applicative
import Data.Functor.Compose
import Data.Semigroup

newtype App (f :: Type -> Type) a = MkApp (f a)
  deriving (Functor, Applicative)

instance (Applicative f, Semigroup a) => Semigroup (App f a) where
  (<>) = liftA2 (<>)

newtype Wat (f :: Type -> Type) (g :: Type -> Type) a = MkWat (App (Compose f g) a)
  deriving Semigroup
