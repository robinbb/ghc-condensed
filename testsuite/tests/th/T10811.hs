{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TemplateHaskell, TypeFamilies #-}

module Bug where

import Data.Kind (Type)

$([d| class C (a :: Type) where
        type F a
        type F a = a |])
