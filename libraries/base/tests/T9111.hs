{-# LANGUAGE Haskell2010 #-}

module T9111 where


import Data.Kind (Constraint, Type)
import Data.Typeable

a = typeRep (Proxy :: Proxy 'True)
b = typeRep (Proxy :: Proxy (Typeable :: Type -> Constraint))
c = typeRep (Proxy :: Proxy ((~) :: Type -> Type -> Constraint))
d = typeRep (Proxy :: Proxy ('Left :: Type -> Either Type Type))
