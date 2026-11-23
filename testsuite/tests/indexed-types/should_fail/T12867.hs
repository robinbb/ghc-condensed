{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}

module T12866 where

import Data.Kind (Type)

type Test2 a = (Eq (TestM a))

class Test a where
    type TestM :: Type
