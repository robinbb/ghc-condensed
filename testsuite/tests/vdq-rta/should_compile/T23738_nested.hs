{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE ExplicitNamespaces #-}

module T23738_nested where

checkEq :: forall a b -> (a ~ b) => ()
checkEq (type _) (type _) = ()

result :: ()
result =
  checkEq
    (type (Either Int Bool))
    (Either (type Int) (type Bool))